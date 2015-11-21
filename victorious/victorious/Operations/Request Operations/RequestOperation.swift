//
//  RequestOperation.swift
//  victorious
//
//  Created by Patrick Lynch on 11/11/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import Foundation
import VictoriousIOSSDK

private let _defaultQueue = NSOperationQueue()

class RequestOperation<T: RequestType> : NSOperation, Queuable {
    
    private(set) var requestError: NSError?
    
    static var sharedQueue: NSOperationQueue { return _defaultQueue }
    
    var mainQueueCompletionBlock: ((NSError?)->())?
    
    private let request: T
    
    var defaultQueue: NSOperationQueue {
        return _defaultQueue
    }
    
    init( request: T ) {
        self.request = request
    }
    
    func cancelAllOperations() {
        for operation in _defaultQueue.operations {
            operation.cancel()
        }
    }
    
    // MARK: - Lifecycle Subclassing
    
    func onStart( completion:()->() ) {
        completion()
    }
    
    func onComplete( result: T.ResultType, completion:()->() ) {
        completion()
    }
    
    func onError( error: NSError ) {}
    
    // MARK: - NSOperation overrides
    
    final override func cancel() {
        super.cancel()
        
        if let request = self.request as? Cancelable {
            request.cancel()
        }
    }
    
    final override func main() {
        let semaphore = dispatch_semaphore_create(0)
        
        let startSemaphore = dispatch_semaphore_create(0)
        dispatch_async( dispatch_get_main_queue() ) {
            self.onStart() {
                dispatch_semaphore_signal( startSemaphore )
            }
        }
        dispatch_semaphore_wait( startSemaphore, DISPATCH_TIME_FOREVER )
        
        let persistentStore = PersistentStore()
        let currentEnvironment = VEnvironmentManager.sharedInstance().currentEnvironment
        let requestContext = RequestContext(v_environment: currentEnvironment)
        let baseURL = currentEnvironment.baseURL
        
        let currentUserID = VUser.currentUser()?.identifier
        let authenticationContext: AuthenticationContext? = persistentStore.sync() { context in
            if let identifier = currentUserID, let currentUser: VUser = context.getObject(identifier) {
                return AuthenticationContext(v_currentUser: currentUser)
            }
            return nil
        }
        
        self.request.execute(
            baseURL: baseURL,
            requestContext: requestContext,
            authenticationContext: authenticationContext,
            callback: { [weak self] (result, error) -> () in
                dispatch_async( dispatch_get_main_queue() ) {
                    guard let strongSelf = self where !strongSelf.cancelled else {
                        return
                    }
                    if let requestError = error as? NSError {
                        strongSelf.requestError = requestError
                        strongSelf.onError( requestError )
                        dispatch_semaphore_signal( semaphore )
                    } else if let requestResult = result {
                        strongSelf.onComplete( requestResult ) {
                            dispatch_semaphore_signal( semaphore )
                        }
                    }
                }
            }
        )
        dispatch_semaphore_wait( semaphore, DISPATCH_TIME_FOREVER )
    }
    
    func queueOn( queue: NSOperationQueue, completionBlock:((NSError?)->())? = nil) {
        if let completionBlock = completionBlock {
            self.mainQueueCompletionBlock = completionBlock
        }
        self.completionBlock = {
            dispatch_async( dispatch_get_main_queue() ) { [weak self] in
                guard let strongSelf = self where !strongSelf.cancelled else {
                    return
                }
                strongSelf.mainQueueCompletionBlock?( strongSelf.requestError )
            }
        }
        _defaultQueue.addOperation( self )
    }
}

private extension AuthenticationContext {
    init?( v_currentUser currentUser: VUser? ) {
        guard let currentUser = currentUser else {
            return nil
        }
        self.init( userID: Int64(currentUser.remoteId.integerValue), token: currentUser.token)
    }
}

private extension RequestContext {
    init( v_environment environment: VEnvironment ) {
        let deviceID = UIDevice.currentDevice().identifierForVendor?.UUIDString ?? ""
        let buildNumber: String
        
        if let buildNumberFromBundle = NSBundle.mainBundle().objectForInfoDictionaryKey("CFBundleVersion") as? String {
            buildNumber = buildNumberFromBundle
        } else {
            buildNumber = ""
        }
        self.init(appID: environment.appID.integerValue, deviceID: deviceID, buildNumber: buildNumber)
    }
}

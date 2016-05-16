//
//  WebSocketNetworkAdapter.swift
//  victorious
//
//  Created by Sebastian Nystorm on 12/4/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import Foundation
import VictoriousCommon

class WebSocketNetworkAdapter: NSObject, NetworkSource {

    private struct Constants {
        static let appIdExpander = "%%APP_ID%%"
        static let tokenExpander = "%%AUTH_TOKEN%%"
    }
    
    private var webSocketController = WebSocketController.sharedInstance
    
    private let dependencyManager: VDependencyManager
    
    // MARK: - Initialization
    
    class func newWithDependencyManager(dependencyManager: VDependencyManager) -> WebSocketNetworkAdapter {
        return WebSocketNetworkAdapter(dependencyManager: dependencyManager)
    }
    
    init(dependencyManager: VDependencyManager) {
        self.dependencyManager = dependencyManager.childDependencyForKey("networkResources")!
        super.init()
        
        // Connect this link in the event chain.
        nextSender = webSocketController

        // Device ID is needed for tracking calls on the backend.
        let deviceID = UIDevice.currentDevice().v_authorizationDeviceID
        webSocketController.setDeviceID(deviceID)
    }
    
    // MARK: ForumEventSender
    
    var nextSender: ForumEventSender?
    
    // MARK: NetworkSource
    
    func setUp() {
        refreshToken()
    }
    
    func tearDown() {
        webSocketController.tearDown()
    }
    
    func addChildReceiver(receiver: ForumEventReceiver) {
        webSocketController.addChildReceiver(receiver)
    }

    func removeChildReceiver(receiver: ForumEventReceiver) {
        webSocketController.removeChildReceiver(receiver)
    }
    
    // MARK: NetworkSourceWebSocket
    
    var isConnected: Bool {
        return webSocketController.isConnected
    }

    /// Don't call this function, the adapter will handle setting of the device ID.
    func setDeviceID(deviceID: String) {
        assertionFailure("Don't call this function, the adapter will handle setting of the device ID.")
    }
    
    /// Don't call this function direcly, use `refreshToken()` instead.
    func replaceToken(token: String) {
        assertionFailure("Don't call this function direcly, use `refreshToken()` instead.")
    }
    
    // MARK: Private
    
    private func expandWebSocketURLString(url: String, withToken token: String, applicationID: String) -> NSURL? {
        let webSocketEndPointUserID = url.stringByReplacingOccurrencesOfString(Constants.appIdExpander, withString: applicationID)
        let webSocketEndPoint = webSocketEndPointUserID.stringByReplacingOccurrencesOfString(Constants.tokenExpander, withString: token)
        return NSURL(string: webSocketEndPoint)
    }
    
    private func refreshToken() {
        guard let currentUserID = VCurrentUser.user()?.remoteId
        where VCurrentUser.isLoggedIn() else {
            assertionFailure("No current user is logged in, how did they even get this far?")
            return
        }

        if let operation = CreateChatServiceTokenOperation(expandableURLString: dependencyManager.expandableTokenURL, currentUserID: currentUserID.integerValue) {
            operation.queue() { [weak self] results, error, canceled in
                guard let strongSelf = self,
                    let token = results?.first as? String where !token.characters.isEmpty else {
                        v_log("Failed to parse the token from the response. Results -> \(results)")
                        return
                }

                let currentApplicationID = VEnvironmentManager.sharedInstance().currentEnvironment.appID
                print("strongSelf.dependencyManager.expandableSocketURL -> \(strongSelf.dependencyManager.expandableSocketURL)  appId -> \(currentApplicationID.stringValue)")
                guard let url = strongSelf.expandWebSocketURLString(strongSelf.dependencyManager.expandableSocketURL, withToken: token, applicationID: currentApplicationID.stringValue) else {
                    v_log("Failed to generate the WebSocket endpoint using token (\(token)), userID (\(currentUserID)) and template URL (\(strongSelf.dependencyManager.expandableSocketURL)))")
                    return
                }
                
                strongSelf.webSocketController.replaceEndPoint(url)
                strongSelf.webSocketController.setUp()
            }
        }
    }
}

private extension VDependencyManager {
    var expandableTokenURL: String {
        return stringForKey("authURL")
    }
    
    var expandableSocketURL: String {
        return stringForKey("socketURL")
    }
}
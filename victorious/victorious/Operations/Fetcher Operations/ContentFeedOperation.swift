//
//  ContentFeedOperation.swift
//  victorious
//
//  Created by Vincent Ho on 5/17/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import Foundation
import VictoriousIOSSDK

final class ContentFeedOperation: NSOperation, Queueable {
    // MARK: - Initializing
    
    init(url: NSURL) {
        super.init()
        
        queuePriority = .VeryHigh
        
        ContentFeedRemoteOperation(url: url).before(self).queue { [weak self] results, error, _ in
            self?.contentIDs = (results as? [String]) ?? []
            self?.error = error
        }
    }
    
    // MARK: - Fetched content
    
    var contentIDs = [String]()
    var items = [ContentModel]()
    var error: NSError?
    
    // MARK: - Executing
    
    override func main() {
        guard error == nil else {
            return
        }
        
        let persistentStore = PersistentStoreSelector.defaultPersistentStore
        
        persistentStore.mainContext.v_performBlockAndWait { [weak self] context in
            self?.items = self?.contentIDs.flatMap {
                return context.v_findOrCreateObject(["v_remoteID": $0]) as VContent
            } ?? []
        }
    }
    
    func executeCompletionBlock(completionBlock: (newItems: [ContentModel], error: NSError?) -> Void) {
        dispatch_async(dispatch_get_main_queue()) {
            completionBlock(newItems: self.items, error: self.error)
        }
    }
}

//
//  RepostSequenceOperation.swift
//  victorious
//
//  Created by Patrick Lynch on 11/17/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import Foundation
import VictoriousIOSSDK

class RepostSequenceOperation: RequestOperation {
    
    private let nodeID: Int64
    
    var request: RepostSequenceRequest
    
    init( nodeID: Int64 ) {
        self.nodeID = nodeID
        self.request = RepostSequenceRequest(nodeID: nodeID)
    }
    
    override func main() {
        
        // Peform optimistic changes before the request is executed
        let semphore = dispatch_semaphore_create(0)
        persistentStore.asyncFromBackground() { context in
            guard let user = VUser.currentUser() else {
                fatalError( "User must be logged in." )
            }
            let node:VNode = context.findOrCreateObject( [ "remoteId" : NSNumber( longLong: self.nodeID) ] )
            node.sequence.hasReposted = true
            node.sequence.repostCount += 1
            user.repostedSequences.insert( node.sequence )
            
            context.saveChanges()
            dispatch_semaphore_signal( semphore )
        }
        dispatch_semaphore_wait( semphore, DISPATCH_TIME_FOREVER )
        
        // Then execute the request
        self.executeRequest( request )
    }
}

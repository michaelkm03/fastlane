//
//  BlockUserOperation.swift
//  victorious
//
//  Created by Sharif Ahmed on 2/25/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import Foundation
import VictoriousIOSSDK

class BlockUserOperation: FetcherOperation {
    
    private let userID: Int
        
    init( userID: Int ) {
        self.userID = userID
    }
    
    override func main() {
        guard didConfirmActionFromDependencies else {
            self.cancel()
            return
        }
        
        BlockUserRemoteOperation(userID: userID).after(self).queue()
        
        persistentStore.createBackgroundContext().v_performBlockAndWait() { context in
            
            let deleteSequenceRequest = NSFetchRequest(entityName: VSequence.v_entityName())
            deleteSequenceRequest.predicate = NSPredicate(format:"user.remoteId == %i", self.userID)
            
            // Delete any "pointer" (a.k.a. "join table") models to sever relationships
            if let sequences: [VSequence] = context.v_executeFetchRequest(deleteSequenceRequest) {
                let deleteStreamItemPointersRequest = NSFetchRequest(entityName: VStreamItemPointer.v_entityName())
                var predicates = [NSPredicate]()
                for sequence in sequences {
                    let predicate = NSPredicate(format: "streamItem.remoteId == %@", sequence.remoteId)
                    predicates.append(predicate)
                }
                deleteStreamItemPointersRequest.predicate = NSCompoundPredicate(orPredicateWithSubpredicates: predicates)
                context.v_deleteObjects(deleteStreamItemPointersRequest)
            }
            
            context.v_deleteObjects(deleteSequenceRequest)
            
            if let users: [VUser] = context.v_findObjects(["remoteId" : self.userID]) {
                for user in users {
                    user.isBlockedByMainUser = NSNumber(bool: true)
                }
            }
            
            //This must bubble up to parent to ensure the parent context knows
            //what sequences have been deleted as soon as this operation completes
            context.v_saveAndBubbleToParentContext()
        }
    }
}

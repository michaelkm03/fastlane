//
//  SuggestedUsersOperation.swift
//  victorious
//
//  Created by Tian Lan on 11/23/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import Foundation
import VictoriousIOSSDK

class SuggestedUsersOperation: RemoteFetcherOperation, RequestOperation {
    
    let request: SuggestedUsersRequest! = SuggestedUsersRequest()
    
    override func main() {
        requestExecutor.executeRequest( request, onComplete: onComplete, onError: nil )
    }
    
    func onComplete( users: SuggestedUsersRequest.ResultType) {
        
        persistentStore.createBackgroundContext().v_performBlockAndWait() { context in
            
            // Parse users and their recent sequences in background context
            let suggestedUsers: [VSuggestedUser] = users.flatMap { sourceModel in
                let user: VUser = context.v_findOrCreateObject(["remoteId": sourceModel.user.userID])
                user.populate(fromSourceModel: sourceModel.user)
                let recentSequences: [VSequence] = sourceModel.recentSequences.flatMap {
                    let sequence: VSequence = context.v_findOrCreateObject(["remoteId": $0.sequenceID])
                    sequence.populate(fromSourceModel: ($0, nil) )
                    return sequence
                }
                return VSuggestedUser( user: user, recentSequences: recentSequences )
            }
            context.v_save()

            let finishOperation = {
                self.results = self.fetchResults( suggestedUsers )
            }

            if NSBundle.v_isTestBundle {
                finishOperation()
            } else {
                dispatch_async( dispatch_get_main_queue() ) {
                    finishOperation()
                }
            }
        }
    }
    
    private func fetchResults( suggestedUsers: [VSuggestedUser] ) -> [VSuggestedUser] {
        return persistentStore.mainContext.v_performBlockAndWait() { context in
            var output = [VSuggestedUser]()
            for suggestedUser in suggestedUsers {
                guard let user = context.objectWithID( suggestedUser.user.objectID ) as? VUser else {
                    fatalError( "Could not load user." )
                }
                let recentSequences: [VSequence] = suggestedUser.recentSequences.flatMap {
                    context.objectWithID( $0.objectID ) as? VSequence
                }
                output.append( VSuggestedUser( user: user, recentSequences: recentSequences ) )
            }
            return output
        }
    }
}
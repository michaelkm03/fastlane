//
//  FollowCountOperation.swift
//  victorious
//
//  Created by Patrick Lynch on 11/19/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import Foundation
import VictoriousIOSSDK

class FollowCountOperation: RequestOperation {
    
    var request: FollowCountRequest
    private let userID: Int64
    
    required init( request: FollowCountRequest ) {
        self.userID = request.userID
        self.request = request
    }
    
    convenience init( userID: Int64 ) {
        self.init( request: FollowCountRequest(userID: userID) )
    }
    
    override func main() {
        requestExecutor.executeRequest( request, onComplete: onComplete, onError: nil )
    }
    
    private func onComplete( response: FollowCountRequest.ResultType, completion:()->() ) {
        persistentStore.backgroundContext.v_performBlock() { context in
            let user: VUser = context.v_findOrCreateObject( [ "remoteId" : Int(self.userID) ])
            user.numberOfFollowers = NSNumber(longLong:response.followersCount)
            user.numberOfFollowing = NSNumber(longLong:response.followingCount)
            context.v_save()
            completion()
        }
    }
}

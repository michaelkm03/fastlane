//
//  ViewedContentStreamRemoteOperation.swift
//  victorious
//
//  Created by Vincent Ho on 5/17/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import UIKit

final class ViewedContentFeedRemoteOperation: RemoteFetcherOperation, PaginatedRequestOperation {
    
    let request: ViewedContentFeedRequest
    
    private var persistentStreamItemIDs: [NSManagedObjectID]?
    
    required init( request: ViewedContentFeedRequest ) {
        self.request = request
    }
    
    convenience init( apiPath: String, sequenceID: String? = nil) {
        self.init( request: ViewedContentFeedRequest(apiPath: apiPath, sequenceID: sequenceID)! )
    }
    
    override func main() {
        requestExecutor.executeRequest( request, onComplete: self.onComplete, onError: nil )
    }
    
    func onComplete( sourceFeed: ViewedContentFeedRequest.ResultType) {
        
        // Make changes on background queue
        persistentStore.createBackgroundContext().v_performBlockAndWait() { context in            
            self.results = sourceFeed.flatMap({
                let viewedContent: VViewedContent = context.v_findOrCreateObject( [ "author.remoteId" : $0.author.userID, "content.remoteID" : $0.content.id ] )
                viewedContent.populate(fromSourceModel: $0)
                return viewedContent.objectID
            })
            context.v_save()
        }
    }
}

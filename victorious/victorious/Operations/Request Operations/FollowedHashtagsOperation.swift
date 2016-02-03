//
//  FollowedHashtagsOperation.swift
//  victorious
//
//  Created by Patrick Lynch on 12/19/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import Foundation
import VictoriousIOSSDK

final class FollowedHashtagsOperation: RequestOperation, PaginatedOperation {
    
    let request: HashtagSubscribedToListRequest
    
    required init( request: HashtagSubscribedToListRequest ) {
        self.request = request
    }
    
    convenience init(paginator: StandardPaginator = StandardPaginator(pageNumber: 1, itemsPerPage: 30)) {
        self.init( request: HashtagSubscribedToListRequest( paginator: paginator ) )
    }
    
    override func main() {
        requestExecutor.executeRequest( request, onComplete: onComplete, onError: nil )
    }
    
    func onComplete( hashtags: HashtagSubscribedToListRequest.ResultType, completion:()->() ) {
        
        storedBackgroundContext = persistentStore.createBackgroundContext().v_performBlock() { context in
            guard let currentUser = VCurrentUser.user(inManagedObjectContext: context) else {
                completion()
                return
            }
        
            var displayOrder = self.request.paginator.displayOrderCounterStart
            for hashtag in hashtags {
                let persistentHashtag: VHashtag = context.v_findOrCreateObject( [ "tag" : hashtag.tag ] )
                persistentHashtag.populate(fromSourceModel: hashtag)
                
                let uniqueInfo = [ "user" : currentUser, "hashtag" : persistentHashtag ]
                let followedHashtag: VFollowedHashtag = context.v_findOrCreateObject( uniqueInfo )
                followedHashtag.user = currentUser
                followedHashtag.hashtag = persistentHashtag
                followedHashtag.displayOrder = displayOrder++
            }
            context.v_save()
            dispatch_async( dispatch_get_main_queue() ) {
                self.results = self.fetchResults()
                completion()
            }
        }
    }
    
    func fetchResults() -> [AnyObject] {
        return persistentStore.mainContext.v_performBlockAndWait() { context in
            guard let currentUser = VCurrentUser.user(inManagedObjectContext: context) else {
                return []
            }
            let fetchRequest = NSFetchRequest(entityName: VFollowedHashtag.v_entityName())
            fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "displayOrder", ascending: true) ]
            let predicate = NSPredicate(
                format: "user.remoteId == %@",
                argumentArray: [ currentUser.remoteId.integerValue ]
            )
            fetchRequest.predicate = predicate
            let results: [VFollowedHashtag] = context.v_executeFetchRequest( fetchRequest )
            return results.map { $0.hashtag }
        }
    }
}
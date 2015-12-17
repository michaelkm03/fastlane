//
//  CommentEditOperation.swift
//  victorious
//
//  Created by Patrick Lynch on 12/15/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import Foundation
import VictoriousIOSSDK

class CommentEditOperation: RequestOperation {
    
    var request: CommentEditRequest
    
    private let text: String
    private let commentID: Int64
    
    private var optimisticCommentObjectID: NSManagedObjectID?
    
    init( commentID: Int64, text: String ) {
        self.commentID = commentID
        self.text = text
        self.request = CommentEditRequest(commentID: commentID, text: text)
    }
    
    override func main() {
        
        // Optimistically edit the comment before sending request
        persistentStore.backgroundContext.v_performBlock() { context in
            if let comment: VComment = context.v_findObjects( ["remoteId" : NSNumber(longLong:self.commentID)] ).first {
                comment.text = self.text
                context.v_save()
                dispatch_sync( dispatch_get_main_queue() ) {
                    self.optimisticCommentObjectID = comment.objectID
                }
            }
        }
        
        // Then fire and forget
        executeRequest( request, onComplete: self.onComplete )
    }
    
    private func onError( error: NSError, completion:()->() ) {
        let params = [ VTrackingKeyErrorMessage : error.localizedDescription ?? "" ]
        VTrackingManager.sharedInstance().trackEvent( VTrackingEventEditCommentDidFail, parameters:params)
        completion()
    }
    
    private func onComplete( comment: CommentAddRequest.ResultType, completion:()->() ) {
        persistentStore.backgroundContext.v_performBlock() { context in
            
            guard let objectID = self.optimisticCommentObjectID,
                let optimisticComment = context.objectWithID( objectID ) as? VComment else {
                    fatalError( "Failed to load comment create optimistically during operation's execution." )
            }
            
            // Repopulate the comment after created on server to provide remoteId and other properties
            optimisticComment.populate( fromSourceModel: comment )
            context.v_save()
            completion()
        }
        
        VTrackingManager.sharedInstance().trackEvent(VTrackingEventUserDidCompleteEditComment)
    }
}

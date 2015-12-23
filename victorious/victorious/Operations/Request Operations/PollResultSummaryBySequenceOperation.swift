//
//  PollResultSummaryBySequenceOperation.swift
//  victorious
//
//  Created by Patrick Lynch on 12/1/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import Foundation
import VictoriousIOSSDK

final class PollResultSummaryBySequenceOperation: RequestOperation, PaginatedOperation {
    
    let request: PollResultSummaryRequest
    var resultCount: Int?
    
    private let sequenceID: Int64
    
    required init( request: PollResultSummaryRequest ) {
        self.sequenceID = request.sequenceID!
        self.request = request
    }
    
    convenience init( sequenceID: Int64 ) {
        self.init( request: PollResultSummaryRequest(sequenceID: sequenceID) )
    }
    
    override func main() {
        executeRequest( request, onComplete: self.onComplete, onError: self.onError )
    }
    
    private func onError( error: NSError, completion:(()->()) ) {
        self.resultCount = 0
        completion()
    }
    
    private func onComplete( pollResults: PollResultSummaryRequest.ResultType, completion:()->() ) {
        
        persistentStore.backgroundContext.v_performBlock() { context in
            
            let sequence: VSequence = context.v_findOrCreateObject( ["remoteId" : String(self.sequenceID)] )
            for pollResult in pollResults where pollResult.sequenceID != nil {
                var uniqueElements = [String : AnyObject]()
                if let answerID = pollResult.answerID {
                    uniqueElements[ "answerId" ] = NSNumber(longLong: answerID)
                }
                if let sequenceID = pollResult.sequenceID {
                    uniqueElements[ "sequenceId" ] = NSNumber(longLong: sequenceID)
                }
                guard !uniqueElements.isEmpty else {
                    continue
                }
                let persistentResult: VPollResult = context.v_findOrCreateObject( uniqueElements )
                persistentResult.populate(fromSourceModel:pollResult)
                persistentResult.sequenceId = String(self.sequenceID)
                persistentResult.sequence = sequence
            }
            
            context.v_save()
            completion()
        }
    }
}

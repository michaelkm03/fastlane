//
//  SequencePollResultsOperation.swift
//  victorious
//
//  Created by Patrick Lynch on 11/18/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import Foundation
import VictoriousIOSSDK

class SequencePollResultsOperation: RequestOperation<PollResultsRequest> {
    
    private let persistentStore: PersistentStoreType = MainPersistentStore()
    private let sequenceID: Int64
    
    init( sequenceID: Int64) {
        self.sequenceID = sequenceID
        super.init(request: PollResultsRequest(sequenceID: sequenceID))
    }
    
    override func onComplete(response: PollResultsRequest.ResultType, completion:()->() ) {
        persistentStore.asyncFromBackground() { context in
            let sequence: VSequence = context.findObjects( [ "remoteId" : Int(self.sequenceID) ] ).first!
            for result in response {
                let pollResult = context.findOrCreateObject( [ "remoteId" : Int(result.answerID) ] ) as VPollResult
                pollResult.sequence = sequence
            }
            context.saveChanges()
            completion()
        }
    }
}

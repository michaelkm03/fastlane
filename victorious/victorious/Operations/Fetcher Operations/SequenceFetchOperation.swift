//
//  SequenceFetchOperation.swift
//  victorious
//
//  Created by Patrick Lynch on 11/17/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import Foundation
import VictoriousIOSSDK

class SequenceFetchOperation: RemoteFetcherOperation, RequestOperation {
    
    let request: SequenceFetchRequest!
    var result: VSequence?
    let streamID: String?
    
    init( sequenceID: String, streamID: String? ) {
        self.request = SequenceFetchRequest(sequenceID: sequenceID)
        self.streamID = streamID
        super.init()
        
        self.qualityOfService = .UserInitiated
    }
    
    override func main() {
        requestExecutor.executeRequest( request, onComplete: onComplete, onError: nil )
    }
    
    private func onComplete( sequence: SequenceFetchRequest.ResultType) {
        
        let persistentSequenceID: NSManagedObjectID = persistentStore.createBackgroundContext().v_performBlockAndWait() { context in
            let persistentSequence: VSequence = context.v_findOrCreateObject([ "remoteId" : sequence.sequenceID ])
            persistentSequence.populate(fromSourceModel: (sequence, nil) )
            context.v_save()
            
            return persistentSequence.objectID
        }
        
        persistentStore.mainContext.v_performBlockAndWait { context in
            self.result = context.objectWithID(persistentSequenceID) as? VSequence
        }
    }
}
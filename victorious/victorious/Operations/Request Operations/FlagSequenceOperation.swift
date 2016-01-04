//
//  FlagSequenceOperation.swift
//  victorious
//
//  Created by Patrick Lynch on 11/17/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import Foundation
import VictoriousIOSSDK

class FlagSequenceOperation: RequestOperation {
    
    private let sequenceID: String
    private let flaggedContent = VFlaggedContent()
    
    let request: FlagSequenceRequest
    
    init( sequenceID: String ) {
        self.request = FlagSequenceRequest(sequenceID: sequenceID)
        self.sequenceID = sequenceID
    }
    
    override func main() {
        requestExecutor.executeRequest( request, onComplete: nil, onError: nil )
    }
    
    func onComplete( stream: FlagSequenceRequest.ResultType, completion:()->() ) {
        persistentStore.backgroundContext.v_performBlock() { context in
            guard let sequence: VSequence = context.v_findObjects([ "remoteId" : String(self.sequenceID) ]).first else {
                completion()
                return
            }
            
            context.deleteObject( sequence )
            context.v_save()
            
            dispatch_async( dispatch_get_main_queue() ) {
                self.flaggedContent.addRemoteId( sequence.remoteId, toFlaggedItemsWithType: .StreamItem)
                completion()
            }
        }
    }
}

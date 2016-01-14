//
//  CreatePollOperation.swift
//  victorious
//
//  Created by Patrick Lynch on 1/5/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import Foundation
import VictoriousIOSSDK

class CreatePollOperation: RequestOperation {
    
    let request: PollCreateRequest!
    
    init?(parameters: PollParameters) {
        self.request = PollCreateRequest(parameters: parameters)
        super.init()
        if request == nil {
            return nil
        }
    }
    
    override func main() {
        requestExecutor.executeRequest( request, onComplete: nil, onError: nil )
    }
}

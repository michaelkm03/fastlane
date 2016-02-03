//
//  PollVoteRequest.swift
//  victorious
//
//  Created by Tian Lan on 11/11/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import Foundation

/// The request for creating user's answer to a poll
public struct PollVoteRequest: RequestType {
    public let sequenceID: String
    public let answerID: Int
    
    public init(sequenceID: String, answerID: Int) {
        self.sequenceID = sequenceID
        self.answerID = answerID
    }
    
    public var urlRequest: NSURLRequest {
        let pollAnswerInfo = [ "answer_id" : answerID, "sequence_id" : sequenceID ]
        
        let request = NSMutableURLRequest(URL: NSURL(string: "/api/pollresult/create")!)
        request.vsdk_addURLEncodedFormPost(pollAnswerInfo)
        return request
    }
}
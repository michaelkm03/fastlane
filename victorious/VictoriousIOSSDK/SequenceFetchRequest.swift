//
//  SequenceFetchRequest.swift
//  victorious
//
//  Created by Patrick Lynch on 11/17/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import Foundation
import SwiftyJSON

public struct SequenceFetchRequest: RequestType {
    
    let sequenceID: Int64
    
    public init( sequenceID: Int64 ) {
        self.sequenceID = sequenceID
    }
    
    public var urlRequest: NSURLRequest {
        let url = NSURL(string:"/api/sequence/fetch")!.URLByAppendingPathComponent( String(self.sequenceID) )
        return NSURLRequest(URL: url)
    }
    
    public func parseResponse(response: NSURLResponse, toRequest request: NSURLRequest, responseData: NSData, responseJSON: JSON) throws -> Sequence {
        if let firstPayloadObject = responseJSON["payload"].arrayValue.first,
            let sequence = Sequence(json: firstPayloadObject) {
                return sequence
        }
        throw ResponseParsingError()
    }
}

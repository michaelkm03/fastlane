//
//  SequenceDetailListByUserRequest.swift
//  victorious
//
//  Created by Tian Lan on 11/20/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import Foundation
import SwiftyJSON

public struct SequenceDetailListByUserRequest: RequestType {
    public let userID: Int
    
    public let paginator: StandardPaginator
    
    public init(request: SequenceDetailListByUserRequest, paginator: StandardPaginator ) {
        self.init( userID: request.userID, paginator: paginator )
    }
    
    public init(userID: Int, paginator: StandardPaginator = StandardPaginator() ) {
        self.userID = userID
        self.paginator = paginator
    }
    
    public var urlRequest: NSURLRequest {
        let url = NSURL(string: "/api/sequence/detail_list_by_user/\(userID)")!
        let request = NSMutableURLRequest(URL: url)
        paginator.addPaginationArgumentsToRequest(request)
        return request
    }
    
    public func parseResponse(response: NSURLResponse, toRequest request: NSURLRequest, responseData: NSData, responseJSON: JSON) throws -> [Sequence] {
        
        guard let sequenceListJSON = responseJSON["payload"].array else {
            throw ResponseParsingError()
        }
        return sequenceListJSON.flatMap { Sequence(json: $0) }
    }
}
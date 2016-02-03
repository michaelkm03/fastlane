//
//  FlagCommentRequest.swift
//  victorious
//
//  Created by Tian Lan on 11/13/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import Foundation

public struct FlagCommentRequest: RequestType {
    
    public let commentID: Int
    
    public init(commentID: Int) {
        self.commentID = commentID
    }
    
    public var urlRequest: NSURLRequest {
        let request = NSMutableURLRequest(URL: NSURL(string: "/api/comment/flag")!)
        request.vsdk_addURLEncodedFormPost(["comment_id": commentID])
        return request
    }
}
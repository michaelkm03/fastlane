//
//  UserUnblockRequest.swift
//  victorious
//
//  Created by Vincent Ho on 6/15/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import Foundation

public struct UserUnblockRequest: RequestType {
    private let url: NSURL
    private let userID: User.ID
    
    public init?(apiPath: APIPath, userID: User.ID) {
        var apiPath = apiPath
        apiPath.macroReplacements["%%USER_ID%%"] = String(userID)
        
        guard let url = apiPath.url else {
            return nil
        }
        
        self.url = url
        self.userID = userID
    }
    
    public var urlRequest: NSURLRequest {
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.vsdk_addURLEncodedFormPost(["user_id": String(userID)])
        return request
    }
}

//
//  CreateAlertRequest.swift
//  victorious
//
//  Created by Patrick Lynch on 12/18/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import Foundation

public struct CreateAlertRequest: RequestType {
    public let additionalParameters: [String: AnyObject]?
    public let type: String
    
    public var urlRequest: NSURLRequest {
        let urlRequest = NSMutableURLRequest(URL: NSURL(string: "/api/alert/create")!)
        
        var requestParameters: [String: AnyObject] = ["type": type]
        
        if let additionalParameters = additionalParameters {
            let jsonData = try! NSJSONSerialization.dataWithJSONObject(additionalParameters, options: [])
            let paramsString = String(data: jsonData, encoding: NSUTF8StringEncoding)
            requestParameters["params"] = paramsString
        }
        
        urlRequest.vsdk_addURLEncodedFormPost(requestParameters)
        return urlRequest
    }
    
    public init(type: String, additionalParameters: [String: AnyObject]? = nil) {
        self.type = type
        self.additionalParameters = additionalParameters
    }
}

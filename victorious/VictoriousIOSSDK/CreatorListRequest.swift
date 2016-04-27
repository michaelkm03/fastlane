//
//  CreatorListRequest.swift
//  victorious
//
//  Created by Tian Lan on 4/22/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import Foundation

/// A network request to retrive the list of creators (API Owners)
/// Response of this request should be `[User]`
public struct CreatorListRequest: RequestType {
    
    private let appIDMacro = "%%APP_ID%%"
    private let url: NSURL
    
    public init?(expandableURLString: String, appID: Int) {
        let expandedURLString = VSDKURLMacroReplacement().urlByReplacingMacrosFromDictionary([appIDMacro: String(appID)], inURLString: expandableURLString)
        guard let url = NSURL(string: expandedURLString) else {
            return nil
        }
        
        self.url = url
    }
    
    public var baseURL: NSURL? {
        return url.baseURL
    }
    
    public var urlRequest: NSURLRequest {
        return NSURLRequest(URL: url)
    }
    
    public func parseResponse(response: NSURLResponse, toRequest request: NSURLRequest, responseData: NSData, responseJSON: JSON) throws -> [User] {
        guard let json = responseJSON["payload"].array else {
            throw ResponseParsingError()
        }
        
        return json.flatMap { User(json: $0) }
    }
}
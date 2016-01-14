//
//  AccountUpdateRequest.swift
//  victorious
//
//  Created by Josh Hinman on 11/9/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import Foundation
import SwiftyJSON

struct AccountUpdateParameters {
    let profileUpdate: ProfileUpdate?
    let passwordUpdate: PasswordUpdate?
}

/// Updates the user's profile and/or password information
public struct AccountUpdateRequest: RequestType {
    
    public let profileUpdate: ProfileUpdate?
    public let passwordUpdate: PasswordUpdate?
    private let requestBody: RequestBodyWriterOutput
    private let requestBodyWriter = AccountUpdateRequestBodyWriter()
    
    public var urlRequest: NSURLRequest {
        let request = NSMutableURLRequest(URL: NSURL(string: "/api/account/update")!)
        request.HTTPMethod = "POST"
        request.HTTPBodyStream = NSInputStream(URL: requestBody.fileURL)
        request.addValue( requestBody.contentType, forHTTPHeaderField: "Content-Type" )
        return request.copy() as! NSURLRequest
    }
    
    public init?(passwordUpdate: PasswordUpdate) {
        self.init( passwordUpdate:passwordUpdate, profileUpdate:nil )
    }
    
    public init?(profileUpdate: ProfileUpdate) {
        self.init( passwordUpdate: nil, profileUpdate:profileUpdate )
    }
    
    public init?(passwordUpdate: PasswordUpdate?, profileUpdate: ProfileUpdate? ) {
        self.profileUpdate = profileUpdate
        self.passwordUpdate = nil
        do {
            self.requestBody = try requestBodyWriter.write(parameters: AccountUpdateParameters(
                profileUpdate: profileUpdate,
                passwordUpdate: passwordUpdate)
            )
        } catch {
            return nil
        }
    }
    
    public func parseResponse(response: NSURLResponse, toRequest request: NSURLRequest, responseData: NSData, responseJSON: JSON) throws -> User {
        requestBodyWriter.removeBodyTempFile()
        
        guard let user = User(json: responseJSON["payload"]) else {
            throw ResponseParsingError()
        }
        return user
    }
}
//
//  TemplateRequestTests.swift
//  victorious
//
//  Created by Josh Hinman on 1/21/16.
//  Copyright © 2016 Victorious. All rights reserved.
//

import SwiftyJSON
import VictoriousIOSSDK
import XCTest

class TemplateRequestTests: XCTestCase {

    func testRequest() {
        let request = TemplateRequest()
        XCTAssertEqual(request.urlRequest.URL?.absoluteString, "/api/template")
    }
    
    func testResponseParser() {
        guard let mockResponseDataURL = NSBundle(forClass: self.dynamicType).URLForResource("template", withExtension: "json"),
            let mockData = NSData(contentsOfURL: mockResponseDataURL) else {
                XCTFail("Error reading mock json data")
                return
        }
        
        do {
            let request = TemplateRequest()
            let results = try request.parseResponse(NSURLResponse(), toRequest: request.urlRequest, responseData: mockData, responseJSON: JSON(data: mockData))
            XCTAssertEqual(results, mockData)
        } catch {
            XCTFail("Sorry, parseResponse should not throw here")
        }
    }
}

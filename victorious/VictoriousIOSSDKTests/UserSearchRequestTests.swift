//
//  UserSearchRequestTests.swift
//  victorious
//
//  Created by Michael Sena on 12/30/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import XCTest
import SwiftyJSON
@testable import VictoriousIOSSDK

class UserSearchRequestTests: XCTestCase {

    func testConfiguredRequest() {
        
        let queryString = "asdf"
        let paginator = StandardPaginator(pageNumber: 2, itemsPerPage: 25)
        let request = UserSearchRequest(query: queryString, paginator: paginator)
        
        XCTAssertEqual(request.urlRequest.URL, NSURL(string:"/api/userinfo/search_paginate/asdf/2/25/message"))
    }
    
    func testParseResponse() {
        
        guard let mockDataURL = NSBundle(forClass: self.dynamicType).URLForResource("TestUserSearchResponse", withExtension: "json"), let mockData = NSData(contentsOfURL: mockDataURL) else {
            XCTFail("Error reading mock json data")
            return
        }
        
        let request = UserSearchRequest(query: "a")
        let results: [User]
        do {
            results = try request.parseResponse(NSURLResponse(), toRequest: NSURLRequest(), responseData: mockData, responseJSON: JSON(data: mockData))
        } catch {
            XCTFail("parse response should not throw")
            return
        }
        XCTAssertEqual(results.count, 15)
        XCTAssertEqual(results[0].userID, 97)
        XCTAssertEqual(results[0].name, "Daily Grace")
    }

}

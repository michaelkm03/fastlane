//
//  HashtagSearchResponseTests.swift
//  victorious
//
//  Created by Cody Kolodziejzyk on 11/9/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import SwiftyJSON
import VictoriousIOSSDK
import XCTest

class HashtagSearchResponseTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testResponseParsing() {
        guard let mockResponseDataURL = NSBundle(forClass: self.dynamicType).URLForResource("HashtagSearchResponse", withExtension: "json"),
            let mockData = NSData(contentsOfURL: mockResponseDataURL) else {
                XCTFail("Error reading mock json data")
                return
        }
        
        do {
            let hashtagSearch = HashtagSearchRequest(searchTerm: "surfer", pageNumber: 1, itemsPerPage: 100)
            let (results, _, previousPage) = try hashtagSearch.parseResponse(NSURLResponse(), toRequest: hashtagSearch.urlRequest, responseData: mockData, responseJSON: JSON(data: mockData))
            XCTAssertEqual(results.count, 2)
            XCTAssertEqual(results[0].hashtagID, 495)
            XCTAssertEqual(results[0].tag, "surfer")
            XCTAssertEqual(results[1].hashtagID, 616)
            XCTAssertEqual(results[1].tag, "surfer2")
            
            XCTAssertNil(previousPage, "There should be no page before page 1")
        } catch {
            XCTFail("Sorry, parseResponse should not throw here")
        }
    }
    
    func testRequest() {
        let hashtagSearch = HashtagSearchRequest(searchTerm: "surfer", pageNumber: 1, itemsPerPage: 100)
        XCTAssertEqual(hashtagSearch.urlRequest.URL?.absoluteString, "/api/hashtag/search/surfer/1/100")
    }
}

//
//  PageableTests.swift
//  victorious
//
//  Created by Patrick Lynch on 12/4/15.
//  Copyright © 2015 Victorious. All rights reserved.
//

import Foundation
import VictoriousIOSSDK
import XCTest

struct MockPageableRequest: PaginatorPageable, ResultBasedPageable {
    
    let paginator: StandardPaginator
    
    init(pageNumber: Int = 1, itemsPerPage: Int = 15) {
        self.paginator = StandardPaginator(pageNumber: pageNumber, itemsPerPage: itemsPerPage)
    }
    
    init(request: MockPageableRequest, paginator: StandardPaginator) {
        self.paginator = paginator
    }
    
    var urlRequest: NSURLRequest {
        let url = NSURL(string: "/api/mock/endpoint")!
        let request = NSMutableURLRequest(URL: url)
        paginator.addPaginationArgumentsToRequest(request)
        return request
    }
}

class PageableTests: XCTestCase {
    
    func testPrevAndNext() {
        let request = MockPageableRequest(pageNumber: 2, itemsPerPage: 10)
        request.paginator.resultCount = request.paginator.itemsPerPage
        let next = MockPageableRequest( nextRequestFromRequest: request )
        XCTAssertNotNil( next )
        XCTAssertEqual( next?.paginator.pageNumber, request.paginator.pageNumber + 1 )
        
        let prev = MockPageableRequest( previousFromSourceRequest: request )
        XCTAssertNotNil( prev )
        XCTAssertEqual( prev?.paginator.pageNumber, request.paginator.pageNumber - 1 )
    }
    
    func testPrevAndNextDoNotExit() {
        let request = MockPageableRequest(pageNumber: 1, itemsPerPage: 10)
        request.paginator.resultCount = request.paginator.itemsPerPage - 1
        var next = MockPageableRequest( nextRequestFromRequest: request )
        XCTAssertNil( next )
        
        request.paginator.resultCount = 0
        next = MockPageableRequest( nextRequestFromRequest: request)
        XCTAssertNil( next )
        
        let prev = MockPageableRequest( previousFromSourceRequest: request )
        XCTAssertNil( prev )
    }
}

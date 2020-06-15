//
// Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

import XCTest
import ClientRuntime

class HttpHeadersTests: XCTestCase {
    
    var headersAsDictionary = [String:String]()
    let testURL = URL(string: "mytest.com")!
    
    override func setUp() {
        headersAsDictionary["header-item-1"] = "header-value-1"
    }

    func testInitWithDictionary() {
        let httpHeaders = HttpHeaders(headersAsDictionary)
        
        XCTAssertEqual(httpHeaders.dictionary, headersAsDictionary)
    }

    func testAddNameValuePairAsHeaderItem() {
        var httpHeaders = HttpHeaders(headersAsDictionary)
        httpHeaders.add(name: "header-item-2", value: "header-value-2")
        
        headersAsDictionary["header-item-2"] = "header-value-2"
        
        XCTAssertEqual(httpHeaders.dictionary, headersAsDictionary)
    }
    
    func testUpdateHeaderItem() {
        var httpHeaders = HttpHeaders(headersAsDictionary)
        let updatedHttpHeader = Header(name: "header-item-1", value: "header-1-value")
        
        //TODO:: add update header using name, value pair
        httpHeaders.update(updatedHttpHeader)
        
        headersAsDictionary["header-item-1"] = "header-1-value"
        
        XCTAssertEqual(httpHeaders.dictionary, headersAsDictionary)
    }
    
    func testAddingExistingHeaderUpdatesIt() {
        var httpHeaders = HttpHeaders(headersAsDictionary)
        httpHeaders.add(name: "header-item-1", value: "header-1-value")
        
        headersAsDictionary["header-item-1"] = "header-1-value"
        
        XCTAssertEqual(httpHeaders.dictionary, headersAsDictionary)
    }
    
    func testCaseInsensitiveHeaderValueFetchingFromName() {
        let httpHeaders = HttpHeaders(headersAsDictionary)
        let headerValue = httpHeaders.value(for: "Header-Item-1")
        
        XCTAssertEqual(headerValue, headersAsDictionary["header-item-1"])
    }
    
    func testGetSetHttpHeadersFromURLRequest() {
        var urlRequest = URLRequest(url: testURL)
        let httpHeaders = HttpHeaders(headersAsDictionary)
        urlRequest.headers = httpHeaders
        
        XCTAssertEqual(urlRequest.headers.dictionary, headersAsDictionary)
    }
    
    func testGetHttpHeadersFromHttpURLResponse() {
        let httpURLResponse = HTTPURLResponse(url: testURL, statusCode: 200, httpVersion: nil, headerFields: headersAsDictionary)
        
        XCTAssertEqual(httpURLResponse!.headers.dictionary, headersAsDictionary)
    }
    
    func testGetSetHttpHeadersFromURLSessionConfiguration() {
        let urlSessionConfiguration = URLSessionConfiguration.default
        let httpHeaders = HttpHeaders(headersAsDictionary)
        urlSessionConfiguration.headers = httpHeaders
        
        XCTAssertEqual(urlSessionConfiguration.headers.dictionary, headersAsDictionary)
    }
}

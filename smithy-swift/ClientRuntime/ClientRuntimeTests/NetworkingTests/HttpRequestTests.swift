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


class HttpRequestTests: XCTestCase {
    
    let path = "/path/to/endpoint"
    var host = "myapi.host.com"
    var queryItems = [URLQueryItem]()
    var endpoint: Endpoint!
    var headers = HttpHeaders()
    var body: String!
    var bodyAsData:String!
    var bodyAsStream: InputStream!
    
    override func setUp() {
        queryItems.append(URLQueryItem(name: "qualifier", value: "qualifier-value"))
        endpoint = Endpoint(host: host, path: path, queryItems: queryItems)
        headers.add(name: "header-item-name", value: "header-item-value")
        body = "{parameter:value}"
    }

    func testHttpDataRequestToUrlRequest() {
        let httpBody = HttpBody.data(body.data(using: .utf8))
        let httpDataRequest = HttpRequest(method: .get, endpoint: endpoint, headers: headers, body: httpBody)
        let urlRequest = try? httpDataRequest.toUrlRequest()
        
        XCTAssertNotNil(urlRequest)
        
        XCTAssertEqual(urlRequest!.headers.dictionary, headers.dictionary)
        XCTAssertEqual(urlRequest!.httpMethod, "GET")
        XCTAssertEqual(String(data: urlRequest!.httpBody!, encoding: .utf8), body)
        XCTAssertEqual(urlRequest!.url, URL(string: "https://myapi.host.com/path/to/endpoint?qualifier=qualifier-value"))
    }
    
    func testHttpStreamRequestToUrlRequest() {
        let httpBody = HttpBody.stream(InputStream(data: body.data(using: .utf8)!))
        let httpDataRequest = HttpRequest(method: .get, endpoint: endpoint, headers: headers, body: httpBody)
        let urlRequest = try? httpDataRequest.toUrlRequest()
        
        XCTAssertNotNil(urlRequest)
        
        XCTAssertEqual(urlRequest!.headers.dictionary, headers.dictionary)
        XCTAssertEqual(urlRequest!.httpMethod, "GET")
        
        let dataFromStream = try? Data(reading: urlRequest!.httpBodyStream!)
        XCTAssertNotNil(dataFromStream)
        
        XCTAssertEqual(String(data: dataFromStream!, encoding: .utf8), body)
        XCTAssertEqual(urlRequest!.url, URL(string: "https://myapi.host.com/path/to/endpoint?qualifier=qualifier-value"))
    }
    
    func testConversionToUrlRequestFailsWithInvalidEndpoint() {
        // TODO:: When is the endpoint invalid or endpoint.url nil?
        endpoint = Endpoint(host: "", path: "", protocolType: nil)
        print(endpoint.url)
        
        let httpBody = HttpBody.data(body.data(using: .utf8))
        let httpDataRequest = HttpRequest(method: .get, endpoint: endpoint, headers: headers, body: httpBody)
        
    }
}

fileprivate extension Data {
    init(reading inputStream: InputStream) throws {
        self.init()
        inputStream.open()
        defer {
            inputStream.close()
        }

        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            buffer.deallocate()
        }
        while inputStream.hasBytesAvailable {
            let read = inputStream.read(buffer, maxLength: bufferSize)
            if read < 0 {
                throw inputStream.streamError!
            } else if read == 0 {
                //EOF
                break
            }
            self.append(buffer, count: read)
        }
    }
}

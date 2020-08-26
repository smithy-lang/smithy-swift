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
@testable import ClientRuntime

class HttpRequestBindingTests: NetworkingTestUtils {

    func testEncodeHttpRequestSetsValidHttpBody() {
        let codableRequest = CodableRequest()
        let uri = "/constant/prefix/\(codableRequest.member)/"
        var httpRequest = codableRequest.buildHttpRequest(method: .get, path: uri)
        
        XCTAssertEqual(httpRequest.endpoint.path, uri)
        XCTAssertEqual(httpRequest.method, .get)
        XCTAssertNil(httpRequest.body)
        
        do {
            _ = try JSONEncoder().encodeHttpRequest(codableRequest, currentHttpRequest: &httpRequest)
        } catch {
            XCTFail("Encoding a valid request failed")
            return
        }

        switch httpRequest.body {
        case .data(let bodyData):
            XCTAssertNotNil(bodyData)
        default:
            XCTFail("Valid body data is expected")
        }
    }

    func testEncodeHttpRequestThrows() {
        let codableRequest = CodableRequestThatThrows()
        let uri = "/constant/prefix/\(codableRequest.member)/"
        var httpRequest = codableRequest.buildHttpRequest(method: .post, path: uri)
        
        XCTAssertEqual(httpRequest.endpoint.path, uri)
        XCTAssertEqual(httpRequest.method, .post)
        XCTAssertNil(httpRequest.body)
        
        XCTAssertThrowsError(try JSONEncoder().encodeHttpRequest(codableRequest, currentHttpRequest: &httpRequest))
    }

    func testEncodeHttpRequestReturnsAsIsForDataInput() {
        let codableRequest = CodableRequestWithPayload()
        let uri = "/constant/prefix/"
        var httpRequest = codableRequest.buildHttpRequest(method: .connect, path: uri)
        
        XCTAssertEqual(httpRequest.endpoint.path, uri)
        XCTAssertEqual(httpRequest.method, .connect)
        XCTAssertNil(httpRequest.body)
        
        do {
            _ = try JSONEncoder().encodeHttpRequest(codableRequest.payload, currentHttpRequest: &httpRequest)
        } catch {
            XCTFail("Encoding a valid request failed")
            return
        }

        switch httpRequest.body {
        case .data(let bodyData):
            XCTAssertEqual(bodyData, codableRequest.payload)
        default:
            XCTFail("Valid body data is expected")
        }
    }

    func testXMLEncodeHttpRequestSetsValidHttpBody() {
        let codableRequest = CodableRequest()
        let uri = "/constant/prefix/\(codableRequest.member)/"
        var httpRequest = codableRequest.buildHttpRequest(method: .get, path: uri)
        
        XCTAssertEqual(httpRequest.endpoint.path, uri)
        XCTAssertEqual(httpRequest.method, .get)
        XCTAssertNil(httpRequest.body)
        
        do {
            _ = try XMLEncoder().encodeHttpRequest(codableRequest, currentHttpRequest: &httpRequest)
        } catch {
            XCTFail("Encoding a valid request failed")
            return
        }

        switch httpRequest.body {
        case .data(let bodyData):
            XCTAssertNotNil(bodyData)
        default:
            XCTFail("Valid body data is expected")
        }
    }
}

struct CodableRequest: Codable {
    var member: String = "value"
}

struct CodableRequestThatThrows: Codable {
    var member: String = "value"

    init() {}

    func encode(to theEncoder: Encoder) throws {
        throw MockError.mockEncodingError
    }
}

struct CodableRequestWithPayload: Codable {
    var payload: Data = "value".data(using: .utf8)!
}

struct CodableXMLRequest: Codable {
    var member: String = "value"
}

enum MockError: Error {
    case mockDecodingError
    case mockEncodingError
}

extension CodableRequest: HttpRequestBinding {
    func buildHttpRequest(method: HttpMethodType, path: String) -> HttpRequest {
        return HttpRequest(method: method, endpoint: Endpoint(host: "codegened-host-for-service", path: path), headers: HttpHeaders())
    }
}

extension CodableXMLRequest: HttpRequestBinding {
    func buildHttpRequest(method: HttpMethodType, path: String) -> HttpRequest {
        return HttpRequest(method: method, endpoint: Endpoint(host: "codegened-host-for-service", path: path), headers: HttpHeaders())
    }
}

extension CodableRequestThatThrows: HttpRequestBinding {
    func buildHttpRequest(method: HttpMethodType, path: String) -> HttpRequest {
        return HttpRequest(method: method, endpoint: Endpoint(host: "codegened-host-for-service", path: path), headers: HttpHeaders())
    }
}

extension CodableRequestWithPayload: HttpRequestBinding {
    func buildHttpRequest(method: HttpMethodType, path: String) -> HttpRequest {
        return HttpRequest(method: method, endpoint: Endpoint(host: "codegened-host-for-service", path: path), headers: HttpHeaders())
    }
}

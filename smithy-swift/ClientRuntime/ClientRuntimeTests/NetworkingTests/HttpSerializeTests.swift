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

class HttpSerializeTests: NetworkingTestUtils {

    func testEncodeBodySetsValidHttpBody() {
        let codableRequest = CodableRequest()
        guard let httpRequest = try? codableRequest.encode() else {
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

    func testEncodeBodyThrows() {
        let codableRequest = CodableRequestThatThrows()
        XCTAssertThrowsError(try codableRequest.encode())
    }

    func testEncodeBodyReturnsPayloadAsItIs() {
        let codableRequest = CodableRequestWithPayload()
        guard let httpRequest = try? codableRequest.encode() else {
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

    func testXMLEncodingSetsValidHttpBody() {
        let codableRequest = CodableXMLRequest()
        guard let httpRequest = try? codableRequest.encode() else {
            XCTFail("Encoding a valid request with XMLEncoder failed")
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

extension CodableRequest: HttpSerialize {
    func encode() throws -> HttpRequest? {
        let httpBody = try encodeBody(self, encoder: JSONEncoder())
        return HttpRequest(method: .get, endpoint: Endpoint(host: "", path: ""), headers: HttpHeaders(), body: httpBody)
    }
}

extension CodableXMLRequest: HttpSerialize {
    func encode() throws -> HttpRequest? {
        let httpBody = try encodeBody(self, encoder: XMLEncoder())
        return HttpRequest(method: .get, endpoint: Endpoint(host: "", path: ""), headers: HttpHeaders(), body: httpBody)
    }
}

extension CodableRequestThatThrows: HttpSerialize {
    func encode() throws -> HttpRequest? {
        let httpBody = try encodeBody(self, encoder: JSONEncoder())
        return HttpRequest(method: .get, endpoint: Endpoint(host: "", path: ""), headers: HttpHeaders(), body: httpBody)
    }
}

extension CodableRequestWithPayload: HttpSerialize {
    func encode() throws -> HttpRequest? {
        let httpBody = try encodeBody(self.payload, encoder: JSONEncoder())
        return HttpRequest(method: .get, endpoint: Endpoint(host: "", path: ""), headers: HttpHeaders(), body: httpBody)
    }
}

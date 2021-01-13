/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import ClientRuntime

class HttpRequestBindingTests: NetworkingTestUtils {

    func testEncodeHttpRequestSetsValidHttpBody() {
        let codableRequest = CodableRequest()
        let uri = "/constant/prefix/\(codableRequest.member)/"
        do {
            let httpRequestBuilder = try codableRequest.buildHttpRequest(encoder: JSONEncoder())
            let httpRequest = httpRequestBuilder.build()
            XCTAssertEqual(httpRequest.method, .get)
        
            switch httpRequest.body {
            case .data(let bodyData):
                XCTAssertNotNil(bodyData)
            default:
                XCTFail("Valid body data is expected")
            }
            
        } catch {
            XCTFail("Encoding a valid request failed")
            return
        }
    }

    func testEncodeHttpRequestThrows() {
        let codableRequest = CodableRequestThatThrows()
        let uri = "/constant/prefix/\(codableRequest.member)/"
        do {
        let httpRequestBuilder = try codableRequest.buildHttpRequest(encoder: JSONEncoder())
        let httpRequest = httpRequestBuilder.build()

        } catch {
          XCTFail()
        }
        
    }

    func testEncodeHttpRequestReturnsAsIsForDataInput() {
        let codableRequest = CodableRequestWithPayload()
        let uri = "/constant/prefix/"
        do {
            let httpRequestBuilder = try codableRequest.buildHttpRequest(encoder: JSONEncoder())
            let httpRequest = httpRequestBuilder.build()
            
            switch httpRequest.body {
            case .data(let bodyData):
                XCTAssertEqual(bodyData, codableRequest.payload)
            default:
                XCTFail("Valid body data is expected")
            }
        } catch {
            XCTFail("Encoding a valid request failed")
            return
        }
    }

    func testXMLEncodeHttpRequestSetsValidHttpBody() {
        let codableRequest = CodableRequest()
        let uri = "/constant/prefix/\(codableRequest.member)/"
        do {
            let httpRequestBuilder = try codableRequest.buildHttpRequest(encoder: XMLEncoder())
            let httpRequest = httpRequestBuilder.build()
            
            switch httpRequest.body {
            case .data(let bodyData):
                XCTAssertNotNil(bodyData)
            default:
                XCTFail("Valid body data is expected")
            }
        } catch {
            XCTFail("Encoding a valid request failed")
            return
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
    func buildHttpRequest(encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequestBuilder {

        let body = HttpBody.data(try encoder.encode(self))
        let builder = SdkHttpRequestBuilder()
            .withBody(body)
            .withHost("codegened-host-for-service")
        return builder
    }
}

extension CodableXMLRequest: HttpRequestBinding {

    func buildHttpRequest(encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequestBuilder {
        let builder = SdkHttpRequestBuilder()
            .withHost("codegened-host-for-service")
        return builder
    }
}

extension CodableRequestThatThrows: HttpRequestBinding {
    func buildHttpRequest(encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequestBuilder {
        let builder = SdkHttpRequestBuilder()
            .withHost("codegened-host-for-service")
        return builder
    }
}

extension CodableRequestWithPayload: HttpRequestBinding {
        func buildHttpRequest(encoder: RequestEncoder, idempotencyTokenGenerator: IdempotencyTokenGenerator = DefaultIdempotencyTokenGenerator()) throws -> SdkHttpRequestBuilder {

        let body = HttpBody.data(self.payload)
        let builder = SdkHttpRequestBuilder()
            .withBody(body)
            .withHost("codegened-host-for-service")
        return builder
    }
}

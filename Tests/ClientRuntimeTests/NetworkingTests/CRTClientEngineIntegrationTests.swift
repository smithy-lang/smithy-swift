/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import ClientRuntime
import AwsCommonRuntimeKit

// These tests are disabled because unreliability of httpbin.org is causing spurious failures.
// Github issue to track correction of these tests: https://github.com/awslabs/aws-sdk-swift/issues/962

class CRTClientEngineIntegrationTests: NetworkingTestUtils {

    var httpClient: SdkHttpClient!
    
    var crtHttpClient: CRTClientEngine!

    override func setUp() {
        super.setUp()
        let httpClientConfiguration = HttpClientConfiguration()
        let crtEngine = CRTClientEngine()
        crtHttpClient = crtEngine
        httpClient = SdkHttpClient(engine: crtEngine, config: httpClientConfiguration)
    }

    override func tearDown() {
        super.tearDown()
    }

    func xtestMakeHttpGetRequest() async throws {
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "httpbin.org")
        let request = SdkHttpRequest(method: .get, endpoint: Endpoint(host: "httpbin.org", path: "/get", headers: headers))
        let response = try await httpClient.send(request: request)

        XCTAssertNotNil(response)
        let statusCode = await response.statusCode
        XCTAssertEqual(statusCode, HttpStatusCode.ok)
    }

    func xtestMakeHttpPostRequest() async throws {
        //used https://httpbin.org
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "httpbin.org")
        let body = TestBody(test: "testval")
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(body)
        let request = SdkHttpRequest(method: .post,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/post", headers: headers),
                                     body: ByteStream.data(encodedData))
        let response = try await httpClient.send(request: request)
        XCTAssertNotNil(response)
        let statusCode = await response.statusCode
        XCTAssertEqual(statusCode, HttpStatusCode.ok)
    }

    func xtestMakeHttpStreamRequestDynamicReceive() async throws {
        //used https://httpbin.org
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "httpbin.org")
        let request = SdkHttpRequest(method: .get,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/stream-bytes/1024", headers: headers),
                                     body: ByteStream.stream(BufferedStream()))
        let response = try await httpClient.send(request: request)
        XCTAssertNotNil(response)
        let statusCode = await response.statusCode
        XCTAssertEqual(statusCode, HttpStatusCode.ok)
    }

    func xtestMakeHttpStreamRequestReceive() async throws {
        //used https://httpbin.org
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "httpbin.org")

        let request = SdkHttpRequest(method: .get,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/stream-bytes/1024", headers: headers),
                                     body: ByteStream.stream(BufferedStream()))
        let response = try await httpClient.send(request: request)
        XCTAssertNotNil(response)
        if case let ByteStream.stream(unwrappedStream) = await response.body {
            let bodyCount = try await unwrappedStream.readToEndAsync()?.count
            XCTAssertEqual(bodyCount, 1024)
        } else {
            XCTFail("Bytes not received")
        }
        let statusCode = await response.statusCode
        XCTAssertEqual(statusCode, HttpStatusCode.ok)
    }

    func xtestMakeHttpStreamRequestReceiveOneByte() async throws {
        //used https://httpbin.org
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "httpbin.org")

        let request = SdkHttpRequest(method: .get,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/stream-bytes/1", headers: headers),
                                     body: ByteStream.stream(BufferedStream()))
        let response = try await httpClient.send(request: request)
        XCTAssertNotNil(response)
        if case let ByteStream.stream(unwrappedStream) = await response.body {
            let bodyCount = try await unwrappedStream.readToEndAsync()?.count
            XCTAssertEqual(bodyCount, 1)
        } else {
            XCTFail("Bytes not received")
        }
        let statusCode = await response.statusCode
        XCTAssertEqual(statusCode, HttpStatusCode.ok)
    }

    func xtestMakeHttpStreamRequestReceive3ThousandBytes() async throws {
        //used https://httpbin.org
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "httpbin.org")

        let request = SdkHttpRequest(method: .get,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/stream-bytes/3000", headers: headers),
                                     body: ByteStream.stream(BufferedStream()))
        let response = try await httpClient.send(request: request)
        XCTAssertNotNil(response)
        if case let ByteStream.stream(unwrappedStream) = await response.body {
            let bodyCount = try await unwrappedStream.readToEndAsync()?.count
            XCTAssertEqual(bodyCount, 3000)
        } else {
            XCTFail("Bytes not received")
        }
        let statusCode = await response.statusCode
        XCTAssertEqual(statusCode, HttpStatusCode.ok)
    }

    func xtestMakeHttpStreamRequestFromData() async throws {
        //used https://httpbin.org
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "httpbin.org")
        let body = TestBody(test: "testval")
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(body)

        let request = SdkHttpRequest(method: .post,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/post", headers: headers),
                                     body: ByteStream.stream(BufferedStream(data: encodedData)))
        let response = try await httpClient.send(request: request)
        XCTAssertNotNil(response)
        let statusCode = await response.statusCode
        XCTAssertEqual(statusCode, HttpStatusCode.ok)
    }
    
    func xtestMakeHttp2StreamRequest() async throws {
        // using http://nghttp2.org/httpbin/#/
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "nghttp2.org")
        let body = TestBody(test: "testval")
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(body)
        
        let request = SdkHttpRequest(
            method: .put,
            endpoint: Endpoint(host: "nghttp2.org", path: "/httpbin/put", headers: headers),
            body: .data(encodedData)
        )
        
        let response = try await crtHttpClient.executeHTTP2Request(request: request)
        switch await response.body {
        case let .stream(stream):
            var data = Data()
            while let next = try stream.read(upToCount: Int.max) {
                data.append(next)
            }
            let decodedBody = try JSONDecoder().decode(ResponseWrapper.self, from: data)
            XCTAssertEqual(decodedBody.json, body)
        case .data, .noStream:
            XCTFail("Unexpected response body type")
        }
    }
}

struct TestBody: Codable, Equatable {
    let test: String
}

struct ResponseWrapper: Decodable {
    let json: TestBody
}

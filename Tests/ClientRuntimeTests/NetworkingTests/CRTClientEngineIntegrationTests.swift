/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import ClientRuntime
import AwsCommonRuntimeKit

class CRTClientEngineIntegrationTests: NetworkingTestUtils {
    
    var httpClient: SdkHttpClient!
    
    override func setUp() {
        super.setUp()
        let httpClientConfiguration = HttpClientConfiguration()
        let crtEngine = try! CRTClientEngine(sdkIO: SDKDefaultIO())
        httpClient = SdkHttpClient(engine: crtEngine, config: httpClientConfiguration)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testMakeHttpGetRequest() async throws {
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "httpbin.org")
        let request = SdkHttpRequest(method: .get, endpoint: Endpoint(host: "httpbin.org", path: "/get"), headers: headers)
        let response = try await httpClient.execute(request: request)
          
        XCTAssertNotNil(response)
        XCTAssert(response.statusCode == HttpStatusCode.ok)
    }
    
    func testMakeHttpPostRequest() async throws {
        //used https://httpbin.org
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "httpbin.org")
        let body = TestBody(test: "testval")
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(body)
        let request = SdkHttpRequest(method: .post,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/post"),
                                     headers: headers,
                                     body: HttpBody.data(encodedData))
        let response = try await httpClient.execute(request: request)
        XCTAssertNotNil(response)
        XCTAssert(response.statusCode == HttpStatusCode.ok)
    }
    
    func testMakeHttpStreamRequestDynamicReceive() async throws {
        //used https://httpbin.org
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "httpbin.org")
        let request = SdkHttpRequest(method: .get,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/stream-bytes/1024"),
                                     headers: headers,
                                     body: HttpBody.stream(ByteStream.defaultReader()))
        let response = try await httpClient.execute(request: request)
        XCTAssertNotNil(response)
        XCTAssert(response.statusCode == HttpStatusCode.ok)
    }
    
    func testMakeHttpStreamRequestReceive() async throws {
        //used https://httpbin.org
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "httpbin.org")
        
        let request = SdkHttpRequest(method: .get,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/stream-bytes/1024"),
                                     headers: headers,
                                     body: HttpBody.stream(ByteStream.defaultReader()))
        let response = try await httpClient.execute(request: request)
        XCTAssertNotNil(response)
        if case let HttpBody.stream(unwrappedStream) = response.body {
            XCTAssert(unwrappedStream.toBytes().length() == 1024)
        } else {
            XCTFail("Bytes not received")
        }
        XCTAssert(response.statusCode == HttpStatusCode.ok)
    }
    
    func testMakeHttpStreamRequestReceiveOneByte() async throws {
        //used https://httpbin.org
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "httpbin.org")
        
        let request = SdkHttpRequest(method: .get,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/stream-bytes/1"),
                                     headers: headers,
                                     body: HttpBody.stream(ByteStream.defaultReader()))
        let response = try await httpClient.execute(request: request)
        XCTAssertNotNil(response)
        if case let HttpBody.stream(unwrappedStream) = response.body {
            XCTAssert(unwrappedStream.toBytes().length() == 1)
        } else {
            XCTFail("Bytes not received")
        }
        XCTAssert(response.statusCode == HttpStatusCode.ok)
    }
    
    func testMakeHttpStreamRequestReceive3ThousandBytes() async throws {
        //used https://httpbin.org
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "httpbin.org")
        
        let request = SdkHttpRequest(method: .get,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/stream-bytes/3000"),
                                     headers: headers,
                                     body: HttpBody.stream(ByteStream.defaultReader()))
        let response = try await httpClient.execute(request: request)
        XCTAssertNotNil(response)
        if case let HttpBody.stream(unwrappedStream) = response.body {
            XCTAssert(unwrappedStream.toBytes().length() == 3000)
        } else {
            XCTFail("Bytes not received")
        }
        XCTAssert(response.statusCode == HttpStatusCode.ok)
    }
    
    func testMakeHttpStreamRequestFromData() async throws {
        //used https://httpbin.org
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "httpbin.org")
        let body = TestBody(test: "testval")
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(body)
        
        let request = SdkHttpRequest(method: .post,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/post"),
                                     headers: headers,
                                     body: HttpBody.stream(.buffer(ByteBuffer(data: encodedData))))
        let response = try await httpClient.execute(request: request)
        XCTAssertNotNil(response)
        XCTAssert(response.statusCode == HttpStatusCode.ok)
    }
}

struct TestBody: Codable {
    let test: String
}

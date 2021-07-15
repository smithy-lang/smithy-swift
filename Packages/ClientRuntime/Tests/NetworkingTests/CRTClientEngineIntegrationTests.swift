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
        let crtEngine = try! CRTClientEngine()
        httpClient = SdkHttpClient(engine: crtEngine, config: httpClientConfiguration)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testMakeHttpGetRequest() {
        let expectation = XCTestExpectation(description: "Request has been completed")
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "httpbin.org")
        let request = SdkHttpRequest(method: .get, endpoint: Endpoint(host: "httpbin.org", path: "/get"), headers: headers)
        httpClient.execute(request: request) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response)
                XCTAssert(response.statusCode == HttpStatusCode.ok)
                expectation.fulfill()
            case .failure(let error):
                print(error)
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }
    
    func testMakeHttpPostRequest() {
        //used https://httpbin.org
        let expectation = XCTestExpectation(description: "Request has been completed")
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "httpbin.org")
        let body = TestBody(test: "testval")
        let encoder = JSONEncoder()
        let encodedData = try! encoder.encode(body)
        let request = SdkHttpRequest(method: .post,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/post"),
                                     headers: headers,
                                     body: HttpBody.data(encodedData))
        httpClient.execute(request: request) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response)
                XCTAssert(response.statusCode == HttpStatusCode.ok)
                expectation.fulfill()
            case .failure(let error):
                print(error)
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    func testMakeHttpStreamRequestDynamicReceive() {
        //used https://httpbin.org
        let expectation = XCTestExpectation(description: "Request has been completed")
        let dataReceivedExpectation = XCTestExpectation(description: "Data was received")
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "httpbin.org")
        let request = SdkHttpRequest(method: .get,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/stream-bytes/1024"),
                                     headers: headers,
                                     body: HttpBody.stream(MockReader(testExpectation: dataReceivedExpectation)))
        httpClient.execute(request: request) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response)
                XCTAssert(response.statusCode == HttpStatusCode.ok)
                expectation.fulfill()
            case .failure(let error):
                print(error)
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation, dataReceivedExpectation], timeout: 20.0)
    }
    
    func testMakeHttpStreamRequestReceive() {
        //used https://httpbin.org
        let expectation = XCTestExpectation(description: "Request has been completed")
        let streamExpectation = XCTestExpectation(description: "Stream data was received")
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "httpbin.org")
        
        let request = SdkHttpRequest(method: .get,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/stream-bytes/1024"),
                                     headers: headers,
                                     body: HttpBody.stream(MockReader(testExpectation: streamExpectation)))
        httpClient.execute(request: request) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response)
                if case let HttpBody.stream(unwrappedStream) = response.body {
                    XCTAssert(unwrappedStream.toBytes().length == 1024)
                } else {
                    XCTFail("Bytes not received")
                }
                XCTAssert(response.statusCode == HttpStatusCode.ok)
                expectation.fulfill()
            case .failure(let error):
                print(error)
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    func testMakeHttpStreamRequestReceiveOneByte() {
        //used https://httpbin.org
        let expectation = XCTestExpectation(description: "Request has been completed")
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "httpbin.org")
        
        let request = SdkHttpRequest(method: .get,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/stream-bytes/1"),
                                     headers: headers,
                                     body: HttpBody.stream(DataContent(data: Data([1]))))
        httpClient.execute(request: request) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response)
                if case let HttpBody.stream(unwrappedStream) = response.body {
                    XCTAssert(unwrappedStream.toBytes().length == 1)
                } else {
                    XCTFail("Bytes not received")
                }
                XCTAssert(response.statusCode == HttpStatusCode.ok)
                expectation.fulfill()
            case .failure(let error):
                print(error)
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    func testMakeHttpStreamRequestReceive3ThousandBytes() {
        //used https://httpbin.org
        let expectation = XCTestExpectation(description: "Request has been completed")
        let streamExpectation = XCTestExpectation(description: "Stream data was receieved")
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "httpbin.org")
        
        let request = SdkHttpRequest(method: .get,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/stream-bytes/3000"),
                                     headers: headers,
                                     body: HttpBody.stream(MockReader(testExpectation: streamExpectation)))
        httpClient.execute(request: request) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response)
                if case let HttpBody.stream(unwrappedStream) = response.body {
                    XCTAssert(unwrappedStream.toBytes().length == 3000)
                } else {
                    XCTFail("Bytes not received")
                }
                XCTAssert(response.statusCode == HttpStatusCode.ok)
                expectation.fulfill()
            case .failure(let error):
                print(error)
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
    
    func testMakeHttpStreamRequestFromData() {
        //used https://httpbin.org
        let expectation = XCTestExpectation(description: "Request has been completed")
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        headers.add(name: "Host", value: "httpbin.org")
        let body = TestBody(test: "testval")
        let encoder = JSONEncoder()
        let encodedData = try! encoder.encode(body)
        
        let request = SdkHttpRequest(method: .post,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/post"),
                                     headers: headers,
                                     body: HttpBody.stream(DataContent(data: encodedData)))
        httpClient.execute(request: request) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response)
                XCTAssert(response.statusCode == HttpStatusCode.ok)
                expectation.fulfill()
            case .failure(let error):
                print(error)
                XCTFail(error.localizedDescription)
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 20.0)
    }
}

// This class implements the StreamSink protocol to simulate how a customer might set up streaming. Only difference
// is it takes an `XCTestExpectation` to fulfill the asynchronous nature of streaming in the unit test.
class MockSinkStream: DataStreamSink {
    override func write(buffer: ByteBuffer) {
        byteBuffer.put(buffer.toData())
        availableForRead += UInt(buffer.length)
        testExpectation.fulfill()
    }
    
    let testExpectation: XCTestExpectation
    
    public init(testExpectation: XCTestExpectation) {
        self.testExpectation = testExpectation
    }
}

struct MockReader: Reader {
    func readFrom() -> StreamSink {
        return MockSinkStream(testExpectation: testExpectation)
    }
    
    var contentLength: Int64? {
        return nil
    }
    let testExpectation: XCTestExpectation
    public init(testExpectation: XCTestExpectation) {
        self.testExpectation = testExpectation
    }
}

struct TestBody: Codable {
    let test: String
}

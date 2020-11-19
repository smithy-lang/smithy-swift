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
        httpClient = try! SdkHttpClient(engine: crtEngine, config: httpClientConfiguration)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testMakeHttpGetRequest() {
        let expectation = XCTestExpectation(description: "Request has been completed")
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
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
        let stream = MockSinkStream(testExpectation: dataReceivedExpectation)
        let request = SdkHttpRequest(method: .get,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/stream-bytes/1024"),
                                     headers: headers,
                                     body: HttpBody.streamSink(.provider(stream)))
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
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        
        let request = SdkHttpRequest(method: .get,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/stream-bytes/1024"),
                                     headers: headers,
                                     body: HttpBody.streamSink(.defaultDataProvider()))

        httpClient.execute(request: request) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response)
                if case let HttpBody.streamSink(unwrappedStream) = response.body {
                    XCTAssert(unwrappedStream.toData()?.count == 1024)
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
        
        let request = SdkHttpRequest(method: .get,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/stream-bytes/1"),
                                     headers: headers,
                                     body: HttpBody.streamSink(.defaultDataProvider()))
        httpClient.execute(request: request) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response)
                if case let HttpBody.streamSink(unwrappedStream) = response.body {
                    XCTAssert(unwrappedStream.toData()?.count == 1)
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
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        
        let request = SdkHttpRequest(method: .get,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/stream-bytes/3000"),
                                     headers: headers,
                                     body: HttpBody.streamSink(.defaultDataProvider()))

        let body = TestBody(test: "testval")
        let encoder = JSONEncoder()
        let encodedData = try! encoder.encode(body)
        let stream = StreamSource(data: encodedData)
        let request = SdkHttpRequest(method: .post,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/post"),
                                     headers: headers,
                                     body: HttpBody.stream(stream))

                if case let HttpBody.streamSink(unwrappedStream) = response.body {
                    XCTAssert(unwrappedStream.toData()?.count == 3000)
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

    func testMakeHttpStreamRequestDynamic() {
        //used https://httpbin.org
        let expectation = XCTestExpectation(description: "Request has been completed")
        let dataExpectation = XCTestExpectation(description: "data was received")
        let streamEndedExpectation = XCTestExpectation(description: "stream has ended")

        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        let body = TestBody(test: "testval")
        let encoder = JSONEncoder()
        let encodedData = try! encoder.encode(body)
        let request = SdkHttpRequest(method: .post,
                                     endpoint: Endpoint(host: "httpbin.org", path: "/post"),
                                     headers: headers,
                                     body: HttpBody.streamSource(.fromData(data: encodedData)))

        httpClient.execute(request: request) { result in
            switch result {
            case .success(let response):
                XCTAssertNotNil(response)

                if let content = response.body {
                    if case let HttpBody.stream(stream) = content {
                        if let stream = stream {
                            let bytes = stream.byteBuffer.toData().count
                            XCTAssert(bytes == 379)
                        }
                    }
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
}

// This class implements the StreamSink protocol to simulate how a customer might set up streaming. Only difference
// is it takes an `XCTestExpectation` to fulfill the asynchronous nature of streaming in the unit test.
class MockSinkStream: StreamSink {
    public var receivedData: Data
    var error: StreamError?
    let testExpectation: XCTestExpectation
    
    public init(testExpectation: XCTestExpectation) {
        self.receivedData = Data()
        self.testExpectation = testExpectation
    }
    func receiveData(readFrom buffer: ByteBuffer) {
        let data = buffer.toData()
        receivedData.append(data)
        testExpectation.fulfill()
    }
    
    func onError(error: StreamError) {
        self.error = error
    }
}

struct TestBody: Encodable {
    let test: String
}

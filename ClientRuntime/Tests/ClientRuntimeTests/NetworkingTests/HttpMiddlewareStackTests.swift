 // Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 // SPDX-License-Identifier: Apache-2.0.

import XCTest
@testable import ClientRuntime

class HttpMiddlewareStackTests: NetworkingTestUtils {
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
    
    func testFullRequest() {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let input = TestBody(test: "testval")
        let requestContext = HttpRequestContextBuilder()
            .withEncoder(value: encoder)
            .withMethod(value: .post)
            .withPath(value: "/post")
            .withServiceName(value: "testService")
            .withOperation(value: "testRequest")
            .build()
        
        let responseContext = HttpResponseContextBuilder()
            .withDecoder(value: decoder)
        
        var requestStack = HttpRequestStack()
        requestStack.add(to: .initialize,
                         position: .before,
                         middleware: BuildRequestMiddleware(input: input))
        
        var responseStack = HttpResponseStack()
        responseStack.add(to: .response,
                          position: .before,
                          middleware: AnyMiddleware(HttpResponseMiddleware<TestResponseError>()))
        responseStack.add(to: .deserialize,
                          position: .before,
                          middleware: AnyMiddleware(DeserializeMiddleware<TestResponse>()))
                          
        let expectation = XCTestExpectation(description: "call came back")
        httpClient.execute(requestContext: requestContext,
                       requestStack: requestStack,
                       responseContext: responseContext,
                       responseStack: responseStack){ (result: SdkResult<TestResponse, TestResponseError>) in
            print(result)
            switch result {
            case .success(let response):
                XCTAssert(response.json?.test == input.test)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }
    
}

 extension TestBody: HttpRequestBinding {
    func buildHttpRequest(method: HttpMethodType, path: String, encoder: RequestEncoder) throws -> SdkHttpRequest {
        let endpoint = Endpoint(host: "httpbin.org", path: path)
        var headers = Headers()
        headers.add(name: "Content-type", value: "application/json")
        let data = try encoder.encode(self)
        let body = HttpBody.data(data)
        return SdkHttpRequest(method: method, endpoint: endpoint, headers: headers, body: body)
    }
 }
 
 struct TestResponse: HttpResponseBinding, Codable {
    let json: TestBody?
    let url: String?
    let origin: String?
    let data: String?
    init(httpResponse: HttpResponse, decoder: ResponseDecoder?) throws {
        if case .data(let data) = httpResponse.body,
            let unwrappedData = data,
            let responseDecoder = decoder {
            let output: TestResponse = try responseDecoder.decode(responseBody: unwrappedData)
            self.json = output.json
            self.url = output.url
            self.origin = output.origin
            self.data = output.data
        } else {
            self.json = nil
            self.url = nil
            self.origin = nil
            self.data = nil
        }
    }
 }

 struct TestResponseError: HttpResponseBinding {
    let statusCode: Int
    init(httpResponse: HttpResponse, decoder: ResponseDecoder?) throws {
        self.statusCode = httpResponse.statusCode.rawValue
    }
 }

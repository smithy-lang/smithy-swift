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
    
    func testMakeHttpRequest() {
        let expectation = XCTestExpectation(description: "Request has been complete")
        var headers = Headers()
        headers.add(name: "TEST", value: "testHeader")
        let request = AsyncRequest(method: .get, endpoint: Endpoint(host: "example.com"), headers: headers, body: nil)
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
}

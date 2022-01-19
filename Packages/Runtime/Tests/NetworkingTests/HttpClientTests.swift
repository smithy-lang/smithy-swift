/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import Runtime

class HttpClientTests: NetworkingTestUtils {

    var httpClient: SdkHttpClient!
    let mockClient = MockHttpClientEngine()

    override func setUp() {
        super.setUp()
        let httpClientConfiguration = HttpClientConfiguration()
        httpClient = SdkHttpClient(engine: mockClient, config: httpClientConfiguration)
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func testExecuteRequest() {
        httpClient.execute(request: mockHttpDataRequest) { (result) in
            switch result {
            case .success(let resp):
                XCTAssertNotNil(resp)
                XCTAssert(resp.statusCode == HttpStatusCode.ok)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        }
    }

}

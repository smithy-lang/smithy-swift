/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import ClientRuntime

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
    
    func testExecuteRequest() async throws {
        let resp = try await httpClient.execute(request: mockHttpDataRequest)
        XCTAssertNotNil(resp)
        XCTAssert(resp.statusCode == HttpStatusCode.ok)
    }
}

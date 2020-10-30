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

class HttpClientTests: NetworkingTestUtils {

    var httpClient: SdkHttpClient!
    let mockClient = MockHttpClientEngine()

    override func setUp() {
        super.setUp()
        let httpClientConfiguration = HttpClientConfiguration(maxConnectionsPerEndpoint: 2, windowSize: 1064, verifyPeer: true)
        httpClient = try! SdkHttpClient(engine: mockClient, config: httpClientConfiguration)
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

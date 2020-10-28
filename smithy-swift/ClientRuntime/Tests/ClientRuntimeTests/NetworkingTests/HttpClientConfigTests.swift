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
import Foundation
@testable import ClientRuntime

class HttpClientConfigTests: NetworkingTestUtils {

    var protocolType: ProtocolType!
    var headers: HttpHeaders = HttpHeaders()
    var protocolClasses: [AnyClass]!

    override func setUp() {
        super.setUp()
        protocolType = .https
        headers.add(name: "header-item-name", value: "header-item-value")
        protocolClasses = [MockURLProtocol.self]
    }

    func testConversionToUrlSessionConfig() {
        let httpClientConfiguration = HttpClientConfiguration(protocolType: protocolType,
                                                              defaultHeaders: headers,
                                                              operationQueue: mockOperationQueue,
                                                              protocolClasses: protocolClasses)
        let urlSessionConfiguration = httpClientConfiguration.toUrlSessionConfig()

        XCTAssertTrue(urlSessionConfiguration.waitsForConnectivity)
        XCTAssertTrue(urlSessionConfiguration.allowsCellularAccess)
        XCTAssertNotNil(urlSessionConfiguration.protocolClasses?.first)

        XCTAssertEqual(urlSessionConfiguration.operationQueue.name, mockOperationQueue.name)
        XCTAssertEqual(urlSessionConfiguration.requestCachePolicy, URLRequest.CachePolicy.reloadIgnoringCacheData)
        XCTAssertEqual(urlSessionConfiguration.networkServiceType, URLRequest.NetworkServiceType.default)
    }
}

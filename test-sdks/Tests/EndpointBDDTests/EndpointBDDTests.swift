//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime
@testable import EndpointBDDTestSDK
import XCTest

/// Tests the endpoint resolver generated for a service that only has the endpointBdd trait.
class EndpointBDDTests: XCTestCase {

    func test_resolve_usesBDD() throws {
        let resolver = try EndpointBDDTestSDK.DefaultEndpointResolver()
        let endpoint = try resolver.resolve(params: EndpointParams(region: "us-east-1"))
        XCTAssertEqual("us-east-1.amazonaws.com", endpoint.uri.host)
        XCTAssertEqual(["us-east-1"], endpoint.headers.values(for: "x-amz-region"))
        XCTAssertEqual(["*", "us-east-1"], endpoint.headers.values(for: "x-amz-multi"))
    }

    func test_resolve_regionUnset_throws() {
        XCTAssertThrowsError(try EndpointBDDTestSDK.DefaultEndpointResolver().resolve(params: EndpointParams()))
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class SmithyHTTPAuth.BearerTokenSigner
import class SmithyHTTPAPI.SdkHttpRequestBuilder
import struct Smithy.Attributes
import struct SmithyIdentity.BearerTokenIdentity
import XCTest

class BearerTokenSignerTests: XCTestCase {
    func testSignRequest() async throws {
        let tokenIdentity = BearerTokenIdentity(token: "dummy-token-for-test")
        let unsignedRequest = SdkHttpRequestBuilder()
        let signer = BearerTokenSigner()
        let signedRequest = try await signer.signRequest(requestBuilder: unsignedRequest, identity: tokenIdentity, signingProperties: Attributes())
        XCTAssert(signedRequest.headers.exists(name: "Authorization"))
        XCTAssertEqual(signedRequest.headers.value(for: "Authorization"), "Bearer \(tokenIdentity.token)")
    }
}

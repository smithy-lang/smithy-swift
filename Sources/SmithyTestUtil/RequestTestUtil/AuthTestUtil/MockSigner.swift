//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import SmithyHTTPAuthAPI
import SmithyHTTPAPI
import SmithyEventStreamsAPI
import SmithyEventStreamsAuthAPI
import ClientRuntime
import Foundation
import SmithyIdentityAPI

public struct MockSigner: Signer {
    public init() {}

    public func signRequest<IdentityT: Identity>(
        requestBuilder: SdkHttpRequestBuilder,
        identity: IdentityT,
        signingProperties: Attributes
    ) async throws -> SdkHttpRequestBuilder {
        requestBuilder.withHeader(name: "Mock-Authorization", value: "Mock-Signed")
        return requestBuilder
    }

    public func signEvent(
        payload: Data,
        previousSignature: String,
        signingProperties: Attributes
    ) async throws -> SigningResult<Message> {
        return SigningResult(output: Message(), signature: "")
    }
}

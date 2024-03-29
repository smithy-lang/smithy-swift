//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime
import Foundation

public struct MockSigner: ClientRuntime.Signer {
    public init() {}

    public func signRequest<IdentityT: Identity>(
        requestBuilder: ClientRuntime.SdkHttpRequestBuilder,
        identity: IdentityT,
        signingProperties: ClientRuntime.Attributes
    ) async throws -> ClientRuntime.SdkHttpRequestBuilder {
        requestBuilder.withHeader(name: "Mock-Authorization", value: "Mock-Signed")
        return requestBuilder
    }

    public func signEvent(
        payload: Data,
        previousSignature: String,
        signingProperties: Attributes
    ) async throws -> SigningResult<EventStream.Message> {
        return SigningResult(output: EventStream.Message(), signature: "")
    }
}

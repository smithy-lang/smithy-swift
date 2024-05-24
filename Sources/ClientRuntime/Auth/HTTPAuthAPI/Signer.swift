//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SmithyEventStreamsAPI

public protocol Signer {
    func signRequest<IdentityT: Identity>(
        requestBuilder: SdkHttpRequestBuilder,
        identity: IdentityT,
        signingProperties: Attributes
    ) async throws -> SdkHttpRequestBuilder

    func signEvent(
        payload: Data,
        previousSignature: String,
        signingProperties: Attributes
    ) async throws -> SigningResult<Message>
}

public struct SigningResult<T> {
    public let output: T
    public let signature: String

    public init(output: T, signature: String) {
        self.output = output
        self.signature = signature
    }
}

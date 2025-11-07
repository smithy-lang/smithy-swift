//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.Attributes
import class SmithyHTTPAPI.HTTPRequestBuilder
import protocol SmithyIdentityAPI.Identity

public protocol Signer: Sendable {

    func signRequest<IdentityT: Identity>(
        requestBuilder: HTTPRequestBuilder,
        identity: IdentityT,
        signingProperties: Attributes
    ) async throws -> HTTPRequestBuilder
}

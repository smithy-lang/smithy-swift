//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class SmithyHTTPAPI.HTTPRequestBuilder
import protocol SmithyIdentityAPI.Identity
import struct Smithy.Attributes

public protocol Signer {

    func signRequest<IdentityT: Identity>(
        requestBuilder: HTTPRequestBuilder,
        identity: IdentityT,
        signingProperties: Attributes
    ) async throws -> HTTPRequestBuilder
}

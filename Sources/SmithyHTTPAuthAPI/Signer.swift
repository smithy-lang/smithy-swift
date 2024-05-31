//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.Attributes
import class SmithyHTTPAPI.SdkHttpRequestBuilder
import protocol SmithyIdentityAPI.Identity

public protocol Signer {

    func signRequest<IdentityT: Identity>(
        requestBuilder: SdkHttpRequestBuilder,
        identity: IdentityT,
        signingProperties: Attributes
    ) async throws -> SdkHttpRequestBuilder
}

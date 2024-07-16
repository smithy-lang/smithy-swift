//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class SmithyHTTPAPI.SdkHttpRequestBuilder
import enum Smithy.ClientError
import protocol SmithyIdentityAPI.Identity
import protocol SmithyHTTPAuthAPI.Signer
import struct Smithy.Attributes
import struct SmithyIdentity.BearerTokenIdentity

/// The signer for HTTP bearer auth.
/// Adds the Authorization header to the request using the resolved bearer token identity as its value.
public class BearerTokenSigner: Signer {
    public func signRequest<IdentityT>(
        requestBuilder: SmithyHTTPAPI.SdkHttpRequestBuilder,
        identity: IdentityT,
        signingProperties: Smithy.Attributes
    ) async throws -> SmithyHTTPAPI.SdkHttpRequestBuilder where IdentityT: SmithyIdentityAPI.Identity {
        guard let identity = identity as? BearerTokenIdentity else {
            throw Smithy.ClientError.authError(
                "Identity passed to the BearerTokenSigner must be of type BearerTokenIdentity."
            )
        }
        return requestBuilder.withHeader(name: "Authorization", value: "Bearer \(identity.token)")
    }
}

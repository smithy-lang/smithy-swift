//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context
import protocol SmithyHTTPAuthAPI.AuthScheme
import protocol SmithyHTTPAuthAPI.Signer
import struct Smithy.Attributes

public struct BearerTokenAuthScheme: AuthScheme {
    public let schemeID: String = "smithy.api#httpBearerAuth"
    public var signer: Signer = BearerTokenSigner()

    public init() {}

    public func customizeSigningProperties(
        signingProperties: Smithy.Attributes,
        context: Smithy.Context
    ) throws -> Smithy.Attributes {
        // no-op
        return signingProperties
    }
}

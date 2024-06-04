//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import SmithyHTTPAuthAPI
import ClientRuntime

public struct MockAuthSchemeA: AuthScheme {
    public let schemeID: String = "MockAuthSchemeA"
    public let signer: Signer = MockSigner()

    public init() {}

    public func customizeSigningProperties(signingProperties: Attributes, context: Context) -> Attributes {
        return signingProperties
    }
}

public struct MockAuthSchemeB: AuthScheme {
    public let schemeID: String = "MockAuthSchemeB"
    public let signer: Signer = MockSigner()

    public init() {}

    public func customizeSigningProperties(signingProperties: Attributes, context: Context) -> Attributes {
        return signingProperties
    }
}

public struct MockAuthSchemeC: AuthScheme {
    public let schemeID: String = "MockAuthSchemeC"
    public let signer: Signer = MockSigner()

    public init() {}

    public func customizeSigningProperties(signingProperties: Attributes, context: Context) -> Attributes {
        return signingProperties
    }
}

public struct MockNoAuth: AuthScheme {
    public let schemeID: String = "smithy.api#noAuth"
    public let signer: Signer = MockSigner()

    public init() {}

    public func customizeSigningProperties(signingProperties: Attributes, context: Context) -> Attributes {
        return signingProperties
    }
}

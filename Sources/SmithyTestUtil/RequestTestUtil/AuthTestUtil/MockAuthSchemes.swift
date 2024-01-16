//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime

public struct MockAuthSchemeA: ClientRuntime.AuthScheme {
    public let schemeID: String = "MockAuthSchemeA"
    public let signer: ClientRuntime.Signer = MockSigner()
    public let idKind: ClientRuntime.IdentityKind = .aws

    public init() {}

    public func customizeSigningProperties(signingProperties: ClientRuntime.Attributes, context: ClientRuntime.HttpContext) -> ClientRuntime.Attributes {
        return signingProperties
    }
}

public struct MockAuthSchemeB: ClientRuntime.AuthScheme {
    public let schemeID: String = "MockAuthSchemeB"
    public let signer: ClientRuntime.Signer = MockSigner()
    public let idKind: ClientRuntime.IdentityKind = .aws

    public init() {}

    public func customizeSigningProperties(signingProperties: ClientRuntime.Attributes, context: ClientRuntime.HttpContext) -> ClientRuntime.Attributes {
        return signingProperties
    }
}

public struct MockAuthSchemeC: ClientRuntime.AuthScheme {
    public let schemeID: String = "MockAuthSchemeC"
    public let signer: ClientRuntime.Signer = MockSigner()
    public let idKind: ClientRuntime.IdentityKind = .aws

    public init() {}

    public func customizeSigningProperties(signingProperties: ClientRuntime.Attributes, context: ClientRuntime.HttpContext) -> ClientRuntime.Attributes {
        return signingProperties
    }
}

public struct MockNoAuth: ClientRuntime.AuthScheme {
    public let schemeID: String = "smithy.api#noAuth"
    public let signer: ClientRuntime.Signer = MockSigner()
    public let idKind: ClientRuntime.IdentityKind = .aws

    public init() {}

    public func customizeSigningProperties(signingProperties: ClientRuntime.Attributes, context: ClientRuntime.HttpContext) -> ClientRuntime.Attributes {
        return signingProperties
    }
}

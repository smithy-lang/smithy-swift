//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyIdentityAPI.Identity
import struct Smithy.Attributes
import struct Smithy.AttributeKey

public struct SelectedAuthScheme: Sendable {
    public let schemeID: String
    public let identity: Identity?
    public let signingProperties: Attributes?
    public let signer: Signer?

    public init(schemeID: String, identity: Identity?, signingProperties: Attributes?, signer: Signer?) {
        self.schemeID = schemeID
        self.identity = identity
        self.signingProperties = signingProperties
        self.signer = signer
    }
}

extension SelectedAuthScheme {
    public func getCopyWithUpdatedSigningProperty<T: Sendable>(key: AttributeKey<T>, value: T) -> SelectedAuthScheme {
        var updatedSigningProperties = self.signingProperties
        updatedSigningProperties?.set(key: key, value: value)
        return SelectedAuthScheme(
            schemeID: self.schemeID,
            identity: self.identity,
            signingProperties: updatedSigningProperties,
            signer: self.signer
        )
    }
}

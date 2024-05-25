//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyAPI.Attributes
import struct SmithyAPI.AttributeKey
import protocol SmithyIdentityAPI.Identity

public struct SelectedAuthScheme {
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
    public func getCopyWithUpdatedSigningProperty<T>(key: AttributeKey<T>, value: T) -> SelectedAuthScheme {
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

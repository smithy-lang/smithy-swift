//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct AuthOption {
    let schemeID: String
    public var identityProperties: Attributes
    public var signingProperties: Attributes

    public init (
        schemeID: String,
        identityProperties: Attributes = Attributes(),
        signingProperties: Attributes = Attributes()
    ) {
        self.schemeID = schemeID
        self.identityProperties = identityProperties
        self.signingProperties = signingProperties
    }
}

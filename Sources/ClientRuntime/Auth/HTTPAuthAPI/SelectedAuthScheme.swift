//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

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

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct SelectedAuthScheme {
    let schemeID: String
    let identity: Identity?
    let signingProperties: Attributes?
    let signer: Signer?
}

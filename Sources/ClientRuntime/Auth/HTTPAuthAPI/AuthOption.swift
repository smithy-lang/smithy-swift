//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct AuthOption {
    let schemeID: String
    var identityProperties: Attributes
    var signingProperties: Attributes
}

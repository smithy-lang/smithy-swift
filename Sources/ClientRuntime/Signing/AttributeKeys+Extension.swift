//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyAPI.AttributeKey

enum AttributeKeys {
    // Keys used to store/retrieve SigningConfig fields in/from signingProperties passed to Signer
    public static let signingAlgorithm = AttributeKey<SigningAlgorithm>(name: "SigningAlgorithm")
}

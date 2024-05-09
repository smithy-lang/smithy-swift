//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension AttributeKeys {
    // Keys used to store/retrieve AWSSigningConfig fields in/from signingProperties passed to AWSSigV4Signer
    public static let signingAlgorithm = AttributeKey<AWSSigningAlgorithm>(name: "SigningAlgorithm")
}

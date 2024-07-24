//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Type of signing algorithm
/// String raw value used for serialization and deserialization
public enum SigningAlgorithm: String {
    ///  Signature Version 4
    case sigv4
    ///  Signature Version 4 Asymmetric
    case sigv4a
}

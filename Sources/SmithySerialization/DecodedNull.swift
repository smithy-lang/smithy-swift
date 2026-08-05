//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// An error indicating that a null was encountered when deserializing a value.
///
/// This error may be handled if null is expected, or thrown back to the caller
/// if not.
@_spi(SchemaBasedSerde)
public struct DecodedNull: Error {

    public init() {}
}

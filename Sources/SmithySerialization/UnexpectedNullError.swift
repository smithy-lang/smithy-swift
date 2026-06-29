//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// An error indicating that a null was encountered in an unexpected context.
@_spi(SchemaBasedSerde)
public struct UnexpectedNullError: Error {

    public init() {}
}

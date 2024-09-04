//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Defines a closure that can be used to convert a wire response to a Swift `Error`.
@_spi(SmithyReadWrite)
public typealias WireResponseErrorClosure<WireResponse> = (WireResponse) async throws -> Error

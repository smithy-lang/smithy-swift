//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Defines a closure that can be used to convert a HTTP response to a Swift `Error`.
public typealias WireResponseErrorClosure<WireResponse> = (WireResponse) async throws -> Error

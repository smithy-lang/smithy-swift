//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Base protocol for client configuration.
///
/// Note: This protocol will inherit `Sendable` after the deprecation period of class-based configurations.
/// The struct-based configuration already conforms to `Sendable` via `@unchecked Sendable`.
public protocol ClientConfiguration {
    init() async throws
}

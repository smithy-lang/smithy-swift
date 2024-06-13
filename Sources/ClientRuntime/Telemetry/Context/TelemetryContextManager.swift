//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A Telemetry Context Manager manages the Telemetry Contexts in a client.
///
/// Implementations should be able to manage contexts in a thread-safe way.
public protocol TelemetryContextManager: Sendable {

    /// - Returns: the current Telemetry Context
    func current() -> TelemetryContext
}

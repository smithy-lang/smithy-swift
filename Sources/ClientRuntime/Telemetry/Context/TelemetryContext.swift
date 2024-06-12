//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A Telemetry Context is a container that can be associated with Tracers and Metrics.
///
/// Context implementations may be containers for execution-scoped values across API boundaries (both in-process and
/// distributed).
public protocol TelemetryContext : Sendable {

    /// Make this context the currently active context.
    ///
    /// - Returns: the scope of the current context
    func makeCurrent() -> TelemetryScope
}

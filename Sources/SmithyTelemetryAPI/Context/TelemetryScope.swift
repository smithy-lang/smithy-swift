//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Delineates a Telemetry Scope that has a beginning and end, particularly for Telemetry Contexts.
public protocol TelemetryScope: Sendable {

    /// Ends the scope.
    func end()
}

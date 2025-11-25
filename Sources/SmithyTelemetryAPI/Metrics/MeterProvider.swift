//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.Attributes

/// A Meter Provider provides implementations of Meters.
public protocol MeterProvider: Sendable {

    /// Provides a Meter.
    ///
    /// - Parameter scope: the name of the instrumentation scope that uniquely identifies this meter
    /// - Parameter attributes: instrumentation scope attributes to associate with emitted telemetry data
    /// - Returns: a Meter
    func getMeter(scope: String, attributes: Attributes?) -> Meter
}

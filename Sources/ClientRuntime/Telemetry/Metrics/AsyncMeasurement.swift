//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.Attributes

/// Handle to stop recording values of an AsyncMeasurement.
public protocol AsyncMeasurementHandle : Sendable {

    /// Stop recording values of an AsyncMeasurement.
    ///
    /// Implementations probably will unregister an AsyncMeasurement callback.
    func stop()
}

public typealias LongAsyncMeasurement = AsyncMeasurement<Int64>

public typealias DoubleAsyncMeasurement = AsyncMeasurement<Double>

/// Async measurement of a specific numeric type.
public protocol AsyncMeasurement<NumericType> {
    associatedtype NumericType: Numeric

    /// Asynchronously records a value for a metric, usually as a callback to an async instrument created by a Meter.
    ///
    /// - Parameter value: value to record
    /// - Parameter attributes: associated attributes, typically of the metric
    /// - Parameter context: context in which value is recorded in
    func record(value: NumericType, attributes: Attributes?, context: TelemetryContext?)
}

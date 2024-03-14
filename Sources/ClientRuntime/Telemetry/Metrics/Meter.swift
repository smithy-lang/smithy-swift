//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A Meter is the entry point to create the instruments.
///
/// The following instrument creation entry points are defined:
///
/// - Gauge
/// - UpDownCounter
/// - Asynchronous UpDownCounter
/// - MonotonicCounter
/// - Asynchronous MonotonicCounter
/// - Histogram
public protocol Meter {
    /// Creates a Gauge, used to measure the current instantaneous value of something.
    ///
    /// Examples include: the current memory used by a process
    ///
    /// - Parameter name: the instrument name
    /// - Parameter callback: callback invoked when a Gauge value is read
    /// - Parameter units: the unit of measure
    /// - Parameter description: a description of the metric
    /// - Returns: handle to stop recording Gauge metrics
    func createGauge(
        name: String,
        callback: @escaping (any DoubleAsyncMeasurement) -> Void,
        units: String?,
        description: String?
    ) -> AsyncMeasurementHandle

    /// Creates an UpDownCounter, used to measure a value that goes up or down.
    ///
    /// Examples include: queue length
    ///
    /// - Parameter name: the instrument name
    /// - Parameter units: the unit of measure
    /// - Parameter description: a description of the metric
    /// - Returns: an UpDownCounter
    func createUpDownCounter(
        name: String,
        units: String?,
        description: String?
    ) -> UpDownCounter

    /// Creates an asynchronous UpDownCounter, used to measure a value that goes up or down.
    ///
    /// Use an asynchronous UpDownCounter instead of a synchronous UpDownCounter when only absolute values are
    /// available, or it would otherwise be expensive to keep track of continuously.
    ///
    /// - Parameter name: the instrument name
    /// - Parameter callback: callback invoked when an UpDownCounter value is recorded
    /// - Parameter units: the unit of measure
    /// - Parameter description: a description of the metric
    /// - Returns: handle to stop recording UpDownCounter metrics
    func createAsyncUpDownCounter(
        name: String,
        callback: @escaping (any LongAsyncMeasurement) -> Void,
        units: String?,
        description: String?
    ) -> AsyncMeasurementHandle

    /// Creates a MonotonicCounter, used to measure a value that only ever increases.
    ///
    /// Examples include: total requests received
    ///
    /// - Parameter name: the instrument name
    /// - Parameter units: the unit of measure
    /// - Parameter description: a description of the metric
    /// - Returns: a MonotonicCounter
    func createCounter(
        name: String,
        units: String?,
        description: String?
    ) -> MonotonicCounter

    /// Creates an asynchronous MonotonicCounter, used to measure a value that only ever increases.
    ///
    /// Use an asynchronous MonotonicCounter instead of a synchronous MonotonicCounter when only absolute values are
    /// available, or it would otherwise be expensive to keep track of continuously.
    ///
    /// - Parameter name: the instrument name
    /// - Parameter callback: callback invoked when an MonotonicCounter value is recorded
    /// - Parameter units: the unit of measure
    /// - Parameter description: a description of the metric
    /// - Returns: handle to stop recording MonotonicCounter metrics
    func createAsyncMonotonicCounter(
        name: String,
        callback: @escaping (any LongAsyncMeasurement) -> Void,
        units: String?,
        description: String?
    ) -> AsyncMeasurementHandle

    /// Creates a Histogram, used to measure a value where the statistics are likely meaningful.
    ///
    /// Examples include: request latency, HTTP response times
    ///
    /// - Parameter name: the instrument name
    /// - Parameter units: the unit of measure
    /// - Parameter description: a description of the metric
    /// - Returns: a Histogram
    func createHistogram(
        name: String,
        units: String?,
        description: String?
    ) -> Histogram
}

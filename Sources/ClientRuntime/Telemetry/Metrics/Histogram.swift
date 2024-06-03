//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.Attributes

/// A Histogram measures a value where the statistics are likely meaningful.
///
/// Examples include: request latency, HTTP response times
public protocol Histogram {

    /// Records a value for a metric.
    ///
    /// - Parameter value: value to record
    /// - Parameter attributes: associated attributes, typically of the metric
    /// - Parameter context: context in which value is recorded in
    func record(value: Double, attributes: Attributes?, context: TelemetryContext?)
}

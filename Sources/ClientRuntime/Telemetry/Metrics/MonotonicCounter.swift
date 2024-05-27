//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.Attributes

/// A Monotonic Counter measures a value that only ever increases.
///
/// Examples include: total requests received
public protocol MonotonicCounter {

    /// Records a value for a metric.
    ///
    /// - Parameter value: value to record
    /// - Parameter attributes: associated attributes, typically of the metric
    /// - Parameter context: context in which value is recorded in
    func add(value: Int64, attributes: Attributes?, context: TelemetryContext?)
}

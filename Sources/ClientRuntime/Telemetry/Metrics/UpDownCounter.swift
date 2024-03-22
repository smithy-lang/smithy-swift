//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// An UpDownCounter measures a value that goes up or down.
///
/// Examples include: queue length
public protocol UpDownCounter {

    /// Records a value for a metric.
    ///
    /// - Parameter value: value to record
    /// - Parameter attributes: associated attributes, typically of the metric
    /// - Parameter context: context in which value is recorded in
    func add(value: Int64, attributes: Attributes?, context: TelemetryContext?)
}

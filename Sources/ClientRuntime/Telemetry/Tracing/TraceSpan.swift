//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyAPI.Attributes
import struct SmithyAPI.AttributeKey

/// A Trace Span represents a single unit of work which has a beginning and end time, and may be connected to other
/// spans as part of a parent / child relationship.
///
/// A span with no parent is considered a root span.
public protocol TraceSpan: TelemetryScope {

    /// The name of the span.
    var name: String { get }

    /// Emits an event to the span.
    ///
    /// - Parameter name: event name
    /// - Parameter attributes: event attributes
    func emitEvent(name: String, attributes: Attributes?)

    /// Set the value for the given attribute key.
    ///
    /// Implementations will want to restrict the value type to the allowed types.
    ///
    /// - Parameter key: attribute key
    /// - Parameter value: attribute value
    func setAttribute<T>(key: AttributeKey<T>, value: T)

    /// Sets the span status.
    ///
    /// - Parameter status: span status to set
    func setStatus(status: TraceSpanStatus)
}

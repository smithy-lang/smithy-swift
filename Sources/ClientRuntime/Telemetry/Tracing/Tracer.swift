//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A Tracer is the entry point for creating spans.
///
/// Implementations MAY provide convenient builder APIs or other extensions to create spans, but ultimately new spans
/// should be created using the tracer interface.
public protocol Tracer {

    /// Create a new Trace Span.
    ///
    /// - Parameter name: name of the span
    /// - Parameter initialAttributes: initial span attributes
    /// - Parameter spanKind: kind of span
    /// - Parameter parentContext: parent context of the span
    /// - Returns: returns the new Trace Span
    func createSpan(
        name: String,
        initialAttributes: Attributes?,
        spanKind: SpanKind,
        parentContext: TelemetryContext?
    ) -> TraceSpan
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A Span Context represents the immutable state that must be serialized and propagated as part of a distributed
/// context.
public protocol SpanContext {
    /// The Trace ID is the unique identifier of the trace which the span belongs to.
    var traceId: String { get }
    /// The Span ID is the unique identifier for the span.
    var spanId: String { get }
    /// Whether the span context was propagated from a remote parent.
    var isRemote: Bool { get }
    /// Whether the span context has a non-zero traceId and non-zero spanId.
    var isValid: Bool { get }
}

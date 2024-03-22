//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// The Kind of Trace Span, which indicates whether a span is a remote child or parent, and whether it is asynchronous.
public enum SpanKind {
    /// An `internal` span is the default kind, which represents an internal operation within a client.
    case `internal`
    /// A `client` span represents a request to a remote service. This span is often the parent of a remote `server`
    /// span and does not end until a response is received.
    case client
    /// A `server` span represents handling a synchronous network request. This span is often the child of a remote
    /// `client` span that is expected to wait for the response.
    case server
    /// A `producer` span represents an asynchronous request. This span is a parent to a corresponding child `consumer`
    /// span and may start and/or end before the child consumer span does.
    case producer
    /// A `consumer` span repesents a child of an asynchronous `producer` request.
    case consumer
}

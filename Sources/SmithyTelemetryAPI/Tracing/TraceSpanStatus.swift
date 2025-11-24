//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Status of a Trace Span.
public enum TraceSpanStatus {
    /// The `unset` status is the default / implicit status.
    case unset
    /// The `ok` status indicates the operation is successful. 
    case ok
    /// The `error` status indicates the operation is unsuccessful.
    case error
}

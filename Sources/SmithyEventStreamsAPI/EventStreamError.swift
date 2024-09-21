//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Event Stream Errors
public enum EventStreamError: Error {

    /// Error thrown when decoding of event stream message fails
    case decoding(String)

    /// Error thrown when message is invalid
    /// This may be due to missing required headers
    case invalidMessage(String)
}

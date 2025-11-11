//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Errors that are particular to the NIO-based Smithy HTTP client.
public enum NIOHTTPClientError: Error {

    /// A URL could not be formed from the `HTTPRequest`.
    /// Please file a bug with aws-sdk-swift if you experience this error.
    case incompleteHTTPRequest

    /// An error occurred during streaming operations.
    /// Please file a bug with aws-sdk-swift if you experience this error.
    case streamingError(Error)
}

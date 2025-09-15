//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Errors that are particular to the NIO-based Smithy HTTP client.
public enum NIOHTTPClientError: Error {

    case streamingError(Error)
}

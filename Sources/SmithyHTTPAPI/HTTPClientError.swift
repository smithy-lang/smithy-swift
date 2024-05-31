//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Errors that may occur when creating a HTTP request.
public enum HTTPClientError: Error {

    /// The path for the HTTP request could not be created.
    case pathCreationFailed(String)

    /// The query items for the HTTP request could not be created.
    case queryItemCreationFailed(String)
}

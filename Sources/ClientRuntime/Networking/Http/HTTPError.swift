/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import class SmithyHTTPAPI.HTTPResponse

/// The protocol with response info for an error that was received over HTTP/HTTPS.
///
/// Any error that is created or code-generated to be received over HTTP will conform
/// to this protocol.
public protocol HTTPError {

    /// The HTTP/HTTPS response that resulted in this error.
    var httpResponse: HTTPResponse { get set }
}

public extension HTTPError {

    /// The ID of the request that resulted in this error, from the response's headers.
    ///
    /// See ``SmithyHTTPAPI/HTTPResponse/requestID`` for the headers it is read from.
    var requestID: String? { httpResponse.requestID }

    /// The second request ID, used by S3, from the response's `x-amz-id-2` header.
    var requestID2: String? { httpResponse.requestID2 }
}

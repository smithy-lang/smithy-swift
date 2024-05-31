/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import class SmithyHTTPAPI.HttpResponse

/// The protocol with response info for an error that was received over HTTP/HTTPS.
///
/// Any error that is created or code-generated to be received over HTTP will conform
/// to this protocol.
public protocol HTTPError {

    /// The HTTP/HTTPS response that resulted in this error.
    var httpResponse: HttpResponse { get }
}

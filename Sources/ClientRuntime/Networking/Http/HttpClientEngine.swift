/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
import AwsCommonRuntimeKit

/// The interface for a client that can be used to perform SDK operations over HTTP.
public protocol HTTPClient {
    
    /// Executes an HTTP request to perform an SDK operation.
    ///
    /// The request must be fully formed (i.e. endpoint resolved, signed, etc.) before sending.  Modifying the request after signature may
    /// result in a rejected request.
    ///
    /// The request body may be in either the form of in-memory data or an asynchronous data stream.
    /// - Parameter request: The HTTP request to be performed.
    /// - Returns: An HTTP response for the request.  Will throw an error if an error is encountered before the HTTP response is received.
    func send(request: SdkHttpRequest) async throws -> HttpResponse
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// The interface for creating the response object that results from a successful HTTP/HTTPS response.
public protocol HttpResponseBinding {

    /// The interface for creating the response object that results from a successful HTTP/HTTPS response.
    init(httpResponse: HttpResponse, decoder: ResponseDecoder?) async throws
}

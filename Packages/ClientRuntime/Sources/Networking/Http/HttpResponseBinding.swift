/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

public protocol HttpResponseBinding {
    init(httpResponse: HttpResponse, decoder: ResponseDecoder?) throws
}

public protocol NoOpHttpResponseBinding: HttpResponseBinding {}
extension NoOpHttpResponseBinding {
    public init(httpResponse: HttpResponse, decoder: ResponseDecoder? = nil) throws {
        //no op default implementation
        try self.init(httpResponse: httpResponse, decoder: decoder)
    }
}

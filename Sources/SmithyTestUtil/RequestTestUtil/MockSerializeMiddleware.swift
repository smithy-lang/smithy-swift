//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Smithy
import SmithyHTTPAPI
import ClientRuntime

public struct MockSerializeMiddleware {
    public typealias MockSerializeMiddlewareCallback = (MockInput, HTTPRequestBuilder, Context) -> Void
    public let id: String
    let headerName: String
    let headerValue: String
    let callback: MockSerializeMiddlewareCallback?

    public init(id: String,
                headerName: String,
                headerValue: String,
                callback: MockSerializeMiddlewareCallback? = nil) {
        self.id = id
        self.headerName = headerName
        self.headerValue = headerValue
        self.callback = callback
    }
}

extension MockSerializeMiddleware: RequestMessageSerializer {
    public typealias InputType = MockInput
    public typealias RequestType = HTTPRequest

    public func apply(input: MockInput, builder: SmithyHTTPAPI.HTTPRequestBuilder, attributes: Smithy.Context) throws {
        if let callback = self.callback {
            callback(input, builder, attributes)
        }
        let path = attributes.path
        let method = attributes.method
        let host = "httpbin.org"
        builder.withHost(host)
            .withHeader(name: "Content-Type", value: "application/json")
            .withHeader(name: headerName, value: headerValue)
            .withHeader(name: "Host", value: host)
            .withPath(path)
            .withMethod(method)
    }
}

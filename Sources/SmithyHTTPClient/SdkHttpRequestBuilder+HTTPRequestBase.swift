//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Date
import struct Foundation.URLComponents
import struct Smithy.URIQueryItem
import class SmithyHTTPAPI.HTTPRequest
import class SmithyHTTPAPI.HTTPRequestBuilder
import struct SmithyHTTPAPI.Headers
import AwsCommonRuntimeKit

extension HTTPRequestBuilder {

    /// Update the builder with the values from the CRT request
    /// - Parameters:
    ///   - crtRequest: the CRT request, this can be either a `HTTPRequest` or a `HTTP2Request`
    ///   - originalRequest: the SDK request that is used to hold the original values
    /// - Returns: the builder
    public func update(
        from crtRequest: HTTPRequestBase,
        originalRequest: HTTPRequest,
        signedAt: Date
    ) -> HTTPRequestBuilder {
        headers = convertSignedHeadersToHeaders(crtRequest: crtRequest)
        withMethod(originalRequest.method)
        withHost(originalRequest.host)
        withSignedAt(signedAt)
        if let crtRequest = crtRequest as? AwsCommonRuntimeKit.HTTPRequest,
           let components = URLComponents(string: crtRequest.path) {
            withPath(components.percentEncodedPath)
            replacingQueryItems(components.percentEncodedQueryItems?.map {
                URIQueryItem(name: $0.name, value: $0.value)
            } ?? [URIQueryItem]())
        } else if crtRequest is HTTP2Request {
            assertionFailure("HTTP2Request not supported")
        } else {
            assertionFailure("Unknown request type")
        }
        return self
    }

    public func convertSignedHeadersToHeaders(crtRequest: HTTPRequestBase) -> Headers {
        return Headers(httpHeaders: crtRequest.getHeaders())
    }
}

extension HTTPRequestBase {
    public var signature: String? {
        let authHeader = getHeaderValue(name: "Authorization")
        guard let signatureSequence = authHeader?.split(separator: "=").last else {
            return nil
        }
        return String(signatureSequence)
    }
}

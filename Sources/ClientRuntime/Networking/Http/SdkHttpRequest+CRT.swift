//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.URI
import class SmithyStreams.StreamableHttpBody
import class SmithyHTTPAPI.SdkHttpRequest
import AwsCommonRuntimeKit

extension SdkHttpRequest {

    public func toHttpRequest() throws -> HTTPRequest {
        let httpRequest = try HTTPRequest()
        httpRequest.method = method.rawValue
        httpRequest.path = [endpoint.path, endpoint.uri.queryString].compactMap { $0 }.joined(separator: "?")
        httpRequest.addHeaders(headers: headers.toHttpHeaders())
        httpRequest.body = isChunked ? nil : StreamableHttpBody(body: body) // body needs to be nil to use writeChunk()
        return httpRequest
    }

    /// Convert the SDK request to a CRT HTTPRequestBase
    /// CRT converts the HTTPRequestBase to HTTP2Request internally if the protocol is HTTP/2
    /// - Returns: the CRT request
    public func toHttp2Request() throws -> HTTPRequestBase {
        let httpRequest = try HTTPRequest()
        httpRequest.method = method.rawValue
        httpRequest.path = [endpoint.path, endpoint.uri.queryString].compactMap { $0 }.joined(separator: "?")
        httpRequest.addHeaders(headers: headers.toHttpHeaders())

        // Remove the "Transfer-Encoding" header if it exists since h2 does not support it
        httpRequest.removeHeader(name: "Transfer-Encoding")

        // HTTP2Request used with manual writes hence we need to set the body to nil
        // so that CRT does not write the body for us (we will write it manually)
        httpRequest.body = nil
        return httpRequest
    }
}

extension SdkHttpRequest {

    var isChunked: Bool {

        // Check if body is a stream
        let isStreamBody: Bool
        switch body {
        case .stream(let stream):
            if stream.isEligibleForChunkedStreaming {
                isStreamBody = true
            } else {
                isStreamBody = false
            }
        default:
            isStreamBody = false
        }

        let isTransferEncodingChunked = headers.value(for: "Transfer-Encoding")?.lowercased() == "chunked"

        return isStreamBody && isTransferEncodingChunked
    }
}

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation
import AwsCommonRuntimeKit

// we need to maintain a reference to this same request while we add headers
// in the CRT engine so that is why it's a class
public class SdkHttpRequest {
    public var body: HttpBody
    public var headers: Headers
    public let queryItems: [URLQueryItem]?
    public let endpoint: Endpoint
    public let method: HttpMethodType
    
    public init(method: HttpMethodType,
                endpoint: Endpoint,
                headers: Headers,
                queryItems: [URLQueryItem]? = nil,
                body: HttpBody = HttpBody.none) {
        self.method = method
        self.endpoint = endpoint
        self.headers = headers
        self.body = body
        self.queryItems = queryItems
    }
}

extension SdkHttpRequest {
    public func toHttpRequest(bufferSize: Int = 1024) -> HttpRequest {
        let httpHeaders = headers.toHttpHeaders()
        let httpRequest = HttpRequest()
        httpRequest.method = method.rawValue
        httpRequest.path = endpoint.path
        httpRequest.addHeaders(headers: httpHeaders)
        var awsInputStream: AwsInputStream?
        switch body {
        case .data(let data):
            if let data = data {
                let byteBuffer = ByteBuffer(data: data)
                awsInputStream = AwsInputStream(byteBuffer)
            }
        case .streamSource(let stream):
            let byteBuffer = ByteBuffer(size: bufferSize)
            stream.unwrap().sendData(writeTo: byteBuffer)
            awsInputStream = AwsInputStream(byteBuffer)
        case .none, .streamSink:
            awsInputStream = nil
        }
        if let inputStream = awsInputStream {
            httpRequest.body = inputStream
        }
        
        return httpRequest
    }
}

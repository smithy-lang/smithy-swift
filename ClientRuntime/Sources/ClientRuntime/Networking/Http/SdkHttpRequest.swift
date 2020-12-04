//
// Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

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

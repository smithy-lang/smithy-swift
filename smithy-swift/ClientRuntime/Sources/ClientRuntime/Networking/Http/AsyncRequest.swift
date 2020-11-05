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


public struct AsyncRequest {
    public var body: HttpBody?
    public let headers: Headers
    public let queryItems: [URLQueryItem]?
    public let endpoint: Endpoint
    public let method: HttpMethodType
    
    public init(method: HttpMethodType,
                endpoint: Endpoint,
                headers: Headers,
                queryItems: [URLQueryItem]? = nil,
                body: HttpBody? = nil) {
        self.method = method
        self.endpoint = endpoint
        self.headers = headers
        self.body = body
        self.queryItems = queryItems
    }
}

extension AsyncRequest {
    public func toHttpRequest() -> HttpRequest {
        let httpRequest = HttpRequest()
        httpRequest.method = method.rawValue
        httpRequest.path = endpoint.path
        httpRequest.addHeaders(headers: headers.toHttpHeaders())
        var bodyToSend: InputStream?
        switch body {
        case .data(let data):
            if let data = data {
                bodyToSend = InputStream(data: data)
            } else {
                bodyToSend = nil
            }
        case .file(let url):
            bodyToSend = InputStream(url: url)
        case .stream(let stream):
            bodyToSend = stream
        case .none:
            bodyToSend = nil
        }
        if let body = bodyToSend {
            httpRequest.body = AwsInputStream(body)
        }
        
        return httpRequest
    }
}

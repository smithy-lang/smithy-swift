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
    }
}

extension AsyncRequest {
<<<<<<< HEAD
    public func toUrlRequest() throws -> URLRequest {
        guard let url = endpoint.url else {

            throw ClientError.serializationFailed("Serialization failed with the url")
        }

        var urlRequest = URLRequest(url: url)
        
        urlRequest.allHTTPHeaderFields = headers.dictionary.mapValues({ (values) -> String in
            values.joined(separator: ", ")
        })

        urlRequest.httpMethod = method.rawValue

=======
    
    public func toHttpRequest() -> HttpRequest {
        let httpRequest = HttpRequest(headers: headers.toHttpHeaders())
        httpRequest.method = method.rawValue
        var bodyToSend: InputStream?
>>>>>>> c554e87... saving progress
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
        if let bodyToSend = bodyToSend {
            httpRequest.body = AwsInputStream(bodyToSend)
        }
        
        return httpRequest
    }
}

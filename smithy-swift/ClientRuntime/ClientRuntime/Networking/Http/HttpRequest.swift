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

public struct HttpRequest {
    public var body: HttpBody?
    public let headers: HttpHeaders
    public let queryItems: [URLQueryItem]?
    public let endpoint: Endpoint
    public let method: HttpMethodType

    public init(method: HttpMethodType,
                endpoint: Endpoint,
                headers: HttpHeaders,
                queryItems: [URLQueryItem]? = nil,
                body: HttpBody? = nil) {
        self.method = method
        self.endpoint = endpoint
        self.headers = headers
        self.queryItems = queryItems
        self.body = body
    }
}

extension HttpRequest {
    public func toUrlRequest() throws -> URLRequest {
        guard let url = endpoint.url else {

            throw ClientError.serializationFailed("Serialization failed with the url")
        }

        var urlRequest = URLRequest(url: url)

        urlRequest.allHTTPHeaderFields = headers.dictionary

        urlRequest.httpMethod = method.rawValue

        switch body {
        case .data(let data):
            urlRequest.httpBody = data
        case .stream(let stream):
            if let stream = stream {
                urlRequest.httpBodyStream = stream
            }
        case .none:
            urlRequest.httpBody = nil
        case .file(let url):
            print(url) //convert to data here or input stream
            let data = try Data(contentsOf: url)
            urlRequest.httpBody = data
        }
        return urlRequest
    }
}

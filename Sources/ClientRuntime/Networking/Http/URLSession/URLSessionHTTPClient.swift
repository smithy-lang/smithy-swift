//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AwsCommonRuntimeKit

public class URLSessionHTTPClient: HttpClientEngine {
    let session = URLSession(configuration: URLSessionConfiguration.default)

    public init() {}

    public func execute(request: SdkHttpRequest) async throws -> HttpResponse {
        let urlRequest = try await makeURLRequest(from: request)
        return try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: urlRequest) { data, urlResponse, error in
                if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    guard let httpResponse = urlResponse as? HTTPURLResponse else {
                        let error = URLSessionHTTPClientError.responseNotHTTP
                        continuation.resume(throwing: error)
                        return
                    }
                    let headers: [HTTPHeader] = httpResponse.allHeaderFields.compactMap { (name, value) in
                        guard let name = name as? String else { return nil }
                        return HTTPHeader(name: name, value: String(describing: value))
                    }
                    let response = HttpResponse(headers: Headers(httpHeaders: headers), body: .data(data), statusCode: HttpStatusCode(rawValue: httpResponse.statusCode) ?? .insufficientStorage)
                    continuation.resume(returning: response)
                }
            }
            task.resume()
        }
    }

    private func makeURLRequest(from request: SdkHttpRequest) async throws -> URLRequest {
        var components = URLComponents()
        components.scheme = request.endpoint.protocolType?.rawValue ?? "https"
        components.host = request.endpoint.host
        components.percentEncodedPath = request.path
        components.percentEncodedQueryItems = request.queryItems?.map { Foundation.URLQueryItem(name: $0.name, value: $0.value) }
        var urlRequest = URLRequest(url: components.url!)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.httpBody = try await request.body.readData()
        for header in request.headers.headers {
            for value in header.value {
                urlRequest.addValue(value, forHTTPHeaderField: header.name)
            }
        }
        return urlRequest
    }
}

public enum URLSessionHTTPClientError: Error {
    case responseNotHTTP
}

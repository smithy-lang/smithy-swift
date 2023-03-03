//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension FoundationHttpClientEngine: HttpClientEngine {
    public func execute(request: ClientRuntime.SdkHttpRequest) async throws -> ClientRuntime.HttpResponse {
        let urlRequest = try self.request(for: request)
        let (data, response) = try await URLSession.shared.upload(for: urlRequest, from: urlRequest.httpBody ?? Data())
        guard let http = response as? HTTPURLResponse else {
            throw ClientError.nonHttpResponse(response)
        }
        let status = HttpStatusCode(rawValue: http.statusCode)
        return ClientRuntime.HttpResponse(headers: self.header(response: http),
                                          body: .stream(ByteStream.buffer(.init(data: data))),
                                          statusCode: status ?? .internalServerError)
    }
}

public struct FoundationHttpClientEngine {

    /// - Tag: FoundationHttpClientEngineClientError
    enum ClientError: Error {

        /// - Tag: FoundationHttpClientEngineClientError.urlError
        case urlError(ClientRuntime.SdkHttpRequest)

        /// - Tag: FoundationHttpClientEngineClientError.nonHttpResponse
        case nonHttpResponse(URLResponse)
    }

    private func url(request: ClientRuntime.SdkHttpRequest) throws -> URL {
        let endpoint = request.endpoint
        var urlString = "\(endpoint.protocolType ?? .https)://\(endpoint.host):\(endpoint.port)\(endpoint.path)"
        if endpoint.queryItemString.isEmpty == false {
            urlString += "\(endpoint.queryItemString)"
        }
        guard let result = URL(string: urlString) else {
            throw ClientError.urlError(request)
        }
        return result
    }

    private func headers(request: ClientRuntime.SdkHttpRequest) -> [String: String] {
        let original = request.headers.dictionary
        var result: [String: String] = [:]
        for (key, value) in original {
            result[key] = String(Array(value).joined(separator: ","))
        }
        return result
    }

    private func request(for request: ClientRuntime.SdkHttpRequest) throws -> URLRequest {
        let url = try self.url(request: request)
        var result = URLRequest(url: url)
        result.allHTTPHeaderFields = self.headers(request: request)
        result.httpMethod = request.method.rawValue

        switch request.body {
        case .data(let data):
            result.httpBody = data
        case .stream(let stream):
            result.httpBody = stream.toBytes().getData()
        case .none:
            result.httpBody = Data()
        }

        return result
    }

    private func header(response: HTTPURLResponse) -> Headers {
        var result: [String : [String]] = [:]
        for (key, value) in response.allHeaderFields {
            guard let keyString = key as? String else {
                continue
            }
            guard let valueString = value as? String else {
                continue
            }
            result[keyString] = [valueString]
        }
        return Headers(result)
    }
}

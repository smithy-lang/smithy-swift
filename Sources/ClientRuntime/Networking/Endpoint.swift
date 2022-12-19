/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

public struct Endpoint: Hashable {
    public let path: String
    public let queryItems: [URLQueryItem]?
    public let protocolType: ProtocolType?
    public let host: String
    public let port: Int16
    
    public let headers: Headers?
    public let properties: [String: AnyHashable]
    
    public init(urlString: String,
                headers: Headers? = nil,
                properties: [String: AnyHashable] = [:]) throws {
        guard let url = URL(string: urlString) else {
            throw ClientError.unknownError("invalid url \(urlString)")
        }
        
        try self.init(url: url, headers: headers, properties: properties)
    }
    
    public init(url: URL,
                headers: Headers? = nil,
                properties: [String: AnyHashable] = [:]) throws {
        guard let host = url.host else {
            throw ClientError.unknownError("invalid host \(String(describing: url.host))")
        }
        
        self.init(host: host,
                  path: url.path,
                  port: Int16(url.port ?? 443),
                  queryItems: url.toQueryItems(),
                  protocolType: ProtocolType(rawValue: url.scheme ?? ProtocolType.https.rawValue),
                  headers: headers,
                  properties: properties)
    }
    
    public init(host: String,
                path: String = "/",
                port: Int16 = 443,
                queryItems: [URLQueryItem]? = nil,
                protocolType: ProtocolType? = .https,
                headers: Headers? = nil,
                properties: [String: AnyHashable] = [:]) {
        self.host = host
        self.path = path
        self.port = port
        self.queryItems = queryItems
        self.protocolType = protocolType
        self.headers = headers
        self.properties = properties
    }
}

public extension Endpoint {
    // We still have to keep 'url' as an optional, since we're
    // dealing with dynamic components that could be invalid.
    var url: URL? {
        var components = URLComponents()
        components.scheme = protocolType?.rawValue
        components.host = host
        components.path = path
        components.percentEncodedQueryItems = queryItems

        return components.url
    }
    
    var queryItemString: String {
        guard let queryItems = queryItems, !queryItems.isEmpty else {
            return ""
        }
        let queryString = queryItems.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: "&")
        return "?\(queryString)"
    }
}

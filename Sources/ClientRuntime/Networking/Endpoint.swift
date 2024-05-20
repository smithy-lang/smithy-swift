/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

public struct Endpoint: Hashable {
    public let path: String
    public let queryItems: [SDKURLQueryItem]?
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

        let protocolType = ProtocolType(rawValue: url.scheme ?? "") ?? .https
        self.init(host: host,
                  path: url.path,
                  port: Int16(url.port ?? protocolType.port),
                  queryItems: url.toQueryItems(),
                  protocolType: protocolType,
                  headers: headers,
                  properties: properties)
    }

    public init(host: String,
                path: String = "/",
                port: Int16 = 443,
                queryItems: [SDKURLQueryItem]? = nil,
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

extension Endpoint {
    // We still have to keep 'url' as an optional, since we're
    // dealing with dynamic components that could be invalid.
    public var url: URL? {
        var components = URLComponents()
        components.scheme = protocolType?.rawValue
        components.host = host.isEmpty ? nil : host // If host is empty, URL is invalid
        components.percentEncodedPath = path
        components.percentEncodedQuery = queryItemString
        return (components.host == nil || components.scheme == nil) ? nil : components.url
    }

    var queryItemString: String? {
        guard let queryItems = queryItems else { return nil }
        return queryItems.map { queryItem in
            return [queryItem.name, queryItem.value].compactMap { $0 }.joined(separator: "=")
        }.joined(separator: "&")
    }

    /// Returns list of auth schemes
    /// This is an internal API and subject to change without notice
    /// - Returns: list of auth schemes if present
    public func authSchemes() -> [[String: Any]]? {
        guard let schemes = properties[AuthSchemeKeys.authSchemes] as? [[String: Any]] else {
            return nil
        }

        return schemes
    }
}

/// Keys used to access auth scheme container and auth scheme properties
private enum AuthSchemeKeys {
    static let authSchemes = "authSchemes"
}

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

public struct Endpoint: Hashable {
    public let uri: URI
    public let protocolType: ProtocolType?
    public var queryItems: [SDKURLQueryItem] { uri.query }
    public var path: String { uri.path }
    public var host: String { uri.host }
    public var port: Int16 { uri.port }
    public var headers: Headers
    public let properties: [String: AnyHashable]

    public init(urlString: String,
                headers: Headers = Headers(),
                properties: [String: AnyHashable] = [:]) throws {
        guard let url = URL(string: urlString) else {
            throw ClientError.unknownError("invalid url \(urlString)")
        }

        try self.init(url: url, headers: headers, properties: properties)
    }

    public init(url: URL,
                headers: Headers = Headers(),
                properties: [String: AnyHashable] = [:]) throws {
        guard let host = url.host else {
            throw ClientError.unknownError("invalid host \(String(describing: url.host))")
        }

        let protocolType = ProtocolType(rawValue: url.scheme ?? "") ?? .https
        let uri = URI(scheme: protocolType.rawValue,
                      path: url.path,
                      host: host,
                      port: Int16(url.port ?? protocolType.port),
                      query: url.toQueryItems() ?? [])
        self.init(uri: uri,
                  protocolType: protocolType,
                  headers: headers,
                  properties: properties)
    }

    public init(host: String,
                path: String = "/",
                port: Int16 = 443,
                queryItems: [SDKURLQueryItem]? = nil,
                headers: Headers = Headers(),
                protocolType: ProtocolType = .https) {
        let uri = URI(scheme: protocolType.rawValue, path: path, host: host, port: port, query: queryItems ?? [])
        self.init(uri: uri, protocolType: protocolType, headers: headers)
    }

    public init(uri: URI,
                protocolType: ProtocolType? = .https,
                headers: Headers = Headers(),
                properties: [String: AnyHashable] = [:]) {
        self.uri = uri
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
        components.host = uri.host.isEmpty ? nil : uri.host // If host is empty, URL is invalid
        components.percentEncodedPath = uri.path
        components.percentEncodedQuery = query
        return (components.host == nil || components.scheme == nil) ? nil : components.url
    }

    var query: String? {
        if (queryItems.isEmpty) {
            return nil
        }
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

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

public struct Endpoint {
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

// It was discovered that in Swift 5.8 and earlier versions, the URLQueryItem type does not correctly implement
// Hashable: namely, multiple URLQueryItems with the same name & value and that are equal by the == operator will have
// different hash values.
//
// Github issue filed against open-source Foundation:
// https://github.com/apple/swift-corelibs-foundation/issues/4737
//
// This extension is intended to correct this problem for the Endpoint type by substituting a
// different structure with the same properties as URLQueryItem when the Endpoint is hashed.
//
// This extension may be removed, and the compiler-generated Hashable compliance may be used instead, once the
// URLQueryItem's Hashable implementation is fixed in open-source Foundation.
extension Endpoint: Hashable {

    private struct QueryItem: Hashable {
        let name: String
        let value: String?
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(path)
        let queryItemElements = queryItems?.map { QueryItem(name: $0.name, value: $0.value) }
        hasher.combine(queryItemElements)
        hasher.combine(protocolType)
        hasher.combine(host)
        hasher.combine(port)
        hasher.combine(headers)
        hasher.combine(properties)
    }
}

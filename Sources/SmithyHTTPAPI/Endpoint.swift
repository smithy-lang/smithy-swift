//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Smithy
import enum AwsCommonRuntimeKit.EndpointProperty

public struct Endpoint: Sendable, Equatable {
    public let uri: URI
    public let headers: Headers
    public var protocolType: URIScheme? { uri.scheme }
    public var queryItems: [URIQueryItem] { uri.queryItems }
    public var path: String { uri.path }
    public var host: String { uri.host }
    public var port: UInt16? { uri.port }
    public var url: URL? { uri.url }
    private let properties: [String: EndpointPropertyValue]

    public init(urlString: String,
                headers: Headers = Headers(),
                properties: [String: EndpointPropertyValue] = [:]) throws {
        guard let url = URLComponents(string: urlString)?.url else {
            throw ClientError.unknownError("invalid url \(urlString)")
        }

        try self.init(url: url, headers: headers, properties: properties)
    }

    public init(url: URL,
                headers: Headers = Headers(),
                properties: [String: EndpointPropertyValue] = [:]) throws {

        guard let host = url.host else {
            throw ClientError.unknownError("invalid host \(String(describing: url.host))")
        }

        let protocolType = URIScheme(rawValue: url.scheme ?? "") ?? .https

        let uri = URIBuilder()
            .withScheme(protocolType)
            .withPath(url.path)
            .withHost(host)
            .withPort(url.port)
            .withQueryItems(getQueryItems(url: url) ?? [])
            .build()

        self.init(uri: uri,
                  headers: headers,
                  properties: properties)
    }

    public init(host: String,
                path: String = "/",
                port: UInt16 = 443,
                queryItems: [URIQueryItem]? = nil,
                headers: Headers = Headers(),
                protocolType: URIScheme? = .https) {

        let uri = URIBuilder()
            .withScheme(protocolType ?? .https)
            .withPath(path)
            .withHost(host)
            .withPort(port)
            .withQueryItems(queryItems ?? [])
            .build()

        self.init(uri: uri, headers: headers)
    }

    public init(uri: URI,
                headers: Headers = Headers(),
                properties: [String: EndpointPropertyValue] = [:]) {
        self.uri = uri
        self.headers = headers
        self.properties = properties
    }
}

extension Endpoint {
    public init(urlString: String,
                headers: Headers = Headers(),
                endpointProperties: [String: EndpointProperty]) throws {
        guard let url = URLComponents(string: urlString)?.url else {
            throw ClientError.unknownError("invalid url \(urlString)")
        }

        let properties = endpointProperties.mapValues(EndpointPropertyValue.init)
        try self.init(url: url, headers: headers, properties: properties)
    }
}

extension Endpoint {

    /// Returns list of auth schemes
    /// This is an internal API and subject to change without notice
    /// - Returns: list of auth schemes if present
    public func authSchemes() -> [[String: EndpointPropertyValue]]? {
        guard let value = properties[AuthSchemeKeys.authSchemes],
              case let .array(schemeArray) = value else {
            return nil
        }

        return schemeArray.compactMap { scheme in
            guard case let .dictionary(dict) = scheme else {
                return nil
            }

            return dict
        }
    }
}

/// Keys used to access auth scheme container and auth scheme properties
private enum AuthSchemeKeys {
    static let authSchemes = "authSchemes"
}

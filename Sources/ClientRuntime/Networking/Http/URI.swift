/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

public struct URI: Hashable {
    public let scheme: Scheme
    public let path: String
    public let host: String
    public let port: Int16
    public let queryItems: [SDKURLQueryItem]
    public let username: String?
    public let password: String?
    public var url: URL? {
        self.toBuilder().getUrl()
    }
    public var queryString: String? {
        if self.queryItems.isEmpty {
            return nil
        }

        return self.queryItems.map { queryItem in
            return [queryItem.name, queryItem.value].compactMap { $0 }.joined(separator: "=")
        }.joined(separator: "&")
    }

    fileprivate init(scheme: Scheme,
                     path: String,
                     host: String,
                     port: Int16,
                     queryItems: [SDKURLQueryItem],
                     username: String? = nil,
                     password: String? = nil) {
        self.scheme = scheme
        self.path = path
        self.host = host
        self.port = port
        self.queryItems = queryItems
        self.username = username
        self.password = password
    }

    public func toBuilder() -> URIBuilder {
        return URIBuilder()
           .withScheme(self.scheme)
           .withPath(self.path)
           .withHost(self.host)
           .withPort(self.port)
           .withQueryItems(self.queryItems)
    }
}

public class URIBuilder {
    var urlComponents: URLComponents
    var scheme: Scheme = Scheme.https
    var path: String = "/"
    var host: String = ""
    var port: Int16 = Int16(Scheme.https.port)
    var queryItems: [SDKURLQueryItem] = []
    var username: String?
    var password: String?

    required public init() {
        self.urlComponents = URLComponents()
        self.urlComponents.scheme = self.scheme.rawValue
        self.urlComponents.path = self.path
        self.urlComponents.host = self.host
    }

    @discardableResult
    public func withScheme(_ value: Scheme?) -> URIBuilder {
        self.scheme = value ?? Scheme.https
        self.urlComponents.scheme = self.scheme.rawValue
        return self
    }

    @discardableResult
    public func withPath(_ value: String) -> URIBuilder {
        self.path = value
        if self.path.contains("%") {
            self.urlComponents.percentEncodedPath = self.path
        } else {
            self.urlComponents.path = self.path
        }
        return self
    }

    @discardableResult
    public func withHost(_ value: String) -> URIBuilder {
        self.host = value
        self.urlComponents.host = self.host
        return self
    }

    @discardableResult
    public func withPort(_ value: Int16) -> URIBuilder {
        self.port = value
        return self
    }

    @discardableResult
    public func withQueryItems(_ value: [SDKURLQueryItem]) -> URIBuilder {
        self.queryItems.append(contentsOf: value)
        if !self.queryItems.isEmpty {
            self.urlComponents.percentEncodedQuery = self.queryItems.map { queryItem in
                            return [queryItem.name, queryItem.value].compactMap { $0 }.joined(separator: "=")
                        }.joined(separator: "&")
        }
        return self
    }

    @discardableResult
    public func withQueryItem(_ value: SDKURLQueryItem) -> URIBuilder {
        withQueryItems([value])
    }

    @discardableResult
    public func withUsername(_ value: String) -> URIBuilder {
        self.username = value
        self.urlComponents.user = self.username
        return self
    }

    @discardableResult
    public func withPassword(_ value: String) -> URIBuilder {
        self.password = value
        self.urlComponents.password = self.password
        return self
    }

    public func build() -> URI {
        return URI(scheme: self.scheme,
                   path: self.path,
                   host: self.host,
                   port: self.port,
                   queryItems: self.queryItems,
                   username: self.username,
                   password: self.password)
    }

    // We still have to keep 'url' as an optional, since we're
    // dealing with dynamic components that could be invalid.
    fileprivate func getUrl() -> URL? {
        return self.path.isEmpty && self.host.isEmpty ? nil : self.urlComponents.url
    }
}

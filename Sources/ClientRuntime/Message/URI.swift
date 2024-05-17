/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

/// A representation of the RFC 3986 Uniform Resource Identifier
public struct URI: Hashable {
    public let scheme: Scheme
    public let path: String
    public let host: String
    public let port: Int16?
    public var defaultPort: Int16 {
        Int16(scheme.port)
    }
    public let queryItems: [SDKURLQueryItem]
    public let username: String?
    public let password: String?
    public let fragment: String?
    public var url: URL? {
        self.toBuilder().getUrl()
    }
    public var queryString: String? {
        self.queryItems.queryString
    }

    fileprivate init(scheme: Scheme,
                     path: String,
                     host: String,
                     port: Int16?,
                     queryItems: [SDKURLQueryItem],
                     username: String? = nil,
                     password: String? = nil,
                     fragment: String? = nil) {
        self.scheme = scheme
        self.path = path
        self.host = host
        self.port = port
        self.queryItems = queryItems
        self.username = username
        self.password = password
        self.fragment = fragment
    }

    public func toBuilder() -> URIBuilder {
        return URIBuilder()
           .withScheme(self.scheme)
           .withPath(self.path)
           .withHost(self.host)
           .withPort(self.port)
           .withQueryItems(self.queryItems)
           .withUsername(self.username)
           .withPassword(self.password)
           .withFragment(self.fragment)
    }
}

/// A builder class for URI
/// The builder performs validation to conform with RFC 3986
public final class URIBuilder {
    var urlComponents: URLComponents

    public init() {
        self.urlComponents = URLComponents()
        self.urlComponents.percentEncodedPath = "/"
        self.urlComponents.scheme = Scheme.https.rawValue
        self.urlComponents.host = ""
    }

    @discardableResult
    public func withScheme(_ value: Scheme) -> URIBuilder {
        self.urlComponents.scheme = value.rawValue
        return self
    }

    @discardableResult
    public func withPath(_ value: String) -> URIBuilder {
        if value.isPercentEncoded {
            self.urlComponents.percentEncodedPath = value
        } else {
            self.urlComponents.path = value
        }
        return self
    }

    @discardableResult
    public func withHost(_ value: String) -> URIBuilder {
        self.urlComponents.host = value
        return self
    }

    @discardableResult
    public func withPort(_ value: Int16?) -> URIBuilder {
        self.urlComponents.port = value.map { Int($0) }
        return self
    }

    @discardableResult
    public func withPort(_ value: Int?) -> URIBuilder {
        self.urlComponents.port = value
        return self
    }

    @discardableResult
    public func withQueryItems(_ value: [SDKURLQueryItem]) -> URIBuilder {
        self.urlComponents.percentEncodedQueryItems = value.isEmpty ? nil : value.toURLQueryItems()
        return self
    }

    @discardableResult
    public func appendQueryItems(_ items: [SDKURLQueryItem]) -> URIBuilder {
        guard !items.isEmpty else {
            return self
        }
        var queryItems = self.urlComponents.percentEncodedQueryItems ?? []
        queryItems += items.toURLQueryItems()
        self.urlComponents.percentEncodedQueryItems = queryItems
        return self
    }

    @discardableResult
    public func appendQueryItem(_ item: SDKURLQueryItem) -> URIBuilder {
        self.appendQueryItems([item])
        return self
    }

    @discardableResult
    public func withUsername(_ value: String?) -> URIBuilder {
        self.urlComponents.user = value
        return self
    }

    @discardableResult
    public func withPassword(_ value: String?) -> URIBuilder {
        self.urlComponents.password = value
        return self
    }

    @discardableResult
    public func withFragment(_ value: String?) -> URIBuilder {
        if let fragment = value {
            if fragment.isPercentEncoded {
                self.urlComponents.percentEncodedFragment = fragment
            } else {
                self.urlComponents.fragment = fragment
            }
        }
        return self
    }

    public func build() -> URI {
        return URI(scheme: Scheme(rawValue: self.urlComponents.scheme!)!,
                   path: self.urlComponents.percentEncodedPath,
                   host: self.urlComponents.host!,
                   port: self.urlComponents.port.map { Int16($0) },
                   queryItems: self.urlComponents.percentEncodedQueryItems?.map {
                        SDKURLQueryItem(name: $0.name, value: $0.value)
                   } ?? [],
                   username: self.urlComponents.user,
                   password: self.urlComponents.password,
                   fragment: self.urlComponents.fragment)
    }

    // We still have to keep 'url' as an optional, since we're
    // dealing with dynamic components that could be invalid.
    fileprivate func getUrl() -> URL? {
        let isInvalidHost = self.urlComponents.host?.isEmpty ?? false
        return isInvalidHost && self.urlComponents.path.isEmpty ? nil : self.urlComponents.url
    }
}

extension String {
    var isPercentEncoded: Bool {
        let decoded = self.removingPercentEncoding
        return decoded != nil && decoded != self
    }
}

extension Array where Element == SDKURLQueryItem {
    public var queryString: String? {
        if self.isEmpty {
            return nil
        }
        return self.map { [$0.name, $0.value].compactMap { $0 }.joined(separator: "=") }.joined(separator: "&")
    }

    public func toURLQueryItems() -> [URLQueryItem] {
        return self.map { URLQueryItem(name: $0.name, value: $0.value) }
    }
}

extension Array where Element == URLQueryItem {
    public func toSDKURLQueryItems() -> [SDKURLQueryItem] {
        return self.map { SDKURLQueryItem(name: $0.name, value: $0.value) }
    }
}

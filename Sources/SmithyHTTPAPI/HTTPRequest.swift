//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.URI
import class Smithy.URIBuilder
import enum Smithy.URIScheme
import struct Smithy.URIQueryItem
import protocol Smithy.RequestMessage
import protocol Smithy.RequestMessageBuilder
import enum Smithy.ByteStream
import enum Smithy.ClientError
import struct Foundation.CharacterSet
import struct Foundation.URLQueryItem
import struct Foundation.URLComponents
// In Linux, Foundation.URLRequest is moved to FoundationNetworking.
#if canImport(FoundationNetworking)
import FoundationNetworking
#else
import struct Foundation.URLRequest
#endif

// we need to maintain a reference to this same request while we add headers
// in the CRT engine so that is why it's a class
// developer must ensure HTTPRequest’s internal state remains thread-safe
public final class HTTPRequest: RequestMessage, @unchecked Sendable {
    public var body: ByteStream
    public let destination: URI
    public var headers: Headers
    public let method: HTTPMethodType
    public var host: String { destination.host }
    public var path: String { destination.path }
    public var queryItems: [URIQueryItem]? { destination.queryItems }
    public var trailingHeaders: Headers = Headers()
    public var endpoint: Endpoint {
        return Endpoint(uri: self.destination, headers: self.headers)
    }

    public convenience init(method: HTTPMethodType,
                            endpoint: Endpoint,
                            body: ByteStream = ByteStream.noStream) {
        self.init(method: method, uri: endpoint.uri, headers: endpoint.headers, body: body)
    }

    public init(method: HTTPMethodType,
                uri: URI,
                headers: Headers,
                body: ByteStream = ByteStream.noStream) {
        self.method = method
        self.destination = uri
        self.headers = headers
        self.body = body
    }

    public func toBuilder() -> HTTPRequestBuilder {
        let builder = HTTPRequestBuilder()
            .withBody(self.body)
            .withMethod(self.method)
            .withHeaders(self.headers)
            .withTrailers(self.trailingHeaders)
            .withPath(self.destination.path)
            .withHost(self.destination.host)
            .withPort(self.destination.port)
            .withProtocol(self.destination.scheme)
            .withQueryItems(self.destination.queryItems)
        return builder
    }

    public func withHeader(name: String, value: String) {
        self.headers.add(name: name, value: value)
    }

    public func withoutHeader(name: String) {
        self.headers.remove(name: name)
    }

    public func withBody(_ body: ByteStream) {
        self.body = body
    }
}

public extension HTTPRequest {

    static func makeURLRequest(from httpRequest: HTTPRequest) async throws -> URLRequest {
        // Set URL
        guard let url = httpRequest.destination.url else {
            throw ClientError.dataNotFound("Failed to construct URLRequest due to missing URL.")
        }
        var urlRequest = URLRequest(url: url)
        // Set method type
        urlRequest.httpMethod = httpRequest.method.rawValue
        // Set body, handling any serialization errors
        do {
            let data = try await httpRequest.body.readData()
            httpRequest.body = .data(data)
            urlRequest.httpBody = data
        } catch {
            throw ClientError.serializationFailed("Failed to construct URLRequest due to HTTP body conversion failure.")
        }
        // Set headers
        httpRequest.headers.headers.forEach { header in
            header.value.forEach { value in
                urlRequest.addValue(value, forHTTPHeaderField: header.name)
            }
        }
        return urlRequest
    }
}

extension HTTPRequest: CustomDebugStringConvertible, CustomStringConvertible {

    public var debugDescriptionWithBody: String {
        return debugDescription + "\nRequestBody: \(body.debugDescription)"
    }

    public var debugDescription: String {
        description
    }

    public var debugDescriptionWithoutAuthorizationHeader: String {
        let method = method.rawValue.uppercased()
        let protocolType = self.destination.scheme
        let query = self.destination.queryString ?? ""
        let port = self.destination.port.map { String($0) } ?? ""
        let header = headers.dictionary
            .filter { key, _ in key != "Authorization" }
            .map { key, value in "\(key): \(value.joined(separator: ", "))"}
            .joined(separator: ", \n")
        return "\(method) \(protocolType):\(port) \n " +
               "Path: \(endpoint.uri.path) \n Headers: \(header) \n Query: \(query)"
    }

    public var description: String {
        let method = method.rawValue.uppercased()
        let protocolType = self.destination.scheme
        let query = self.destination.queryString ?? ""
        let port = self.destination.port.map { String($0) } ?? ""
        return "\(method) \(protocolType):\(port) \n " +
               "Path: \(endpoint.uri.path) \n Headers: \(headers) \n Query: \(query)"
    }
}

public final class HTTPRequestBuilder: RequestMessageBuilder {

    required public init() {}

    public var headers: Headers = Headers()
    public private(set) var methodType: HTTPMethodType = .get
    public private(set) var host: String = ""
    public private(set) var path: String = "/"
    public private(set) var body: ByteStream = .noStream
    public private(set) var queryItems = [URIQueryItem]()
    public private(set) var port: UInt16?
    public private(set) var protocolType: URIScheme = .https
    public private(set) var trailingHeaders: Headers = Headers()

    public var currentQueryItems: [URIQueryItem]? {
        return queryItems
    }

    // We follow the convention of returning the builder object
    // itself from any configuration methods, and by adding the
    // @discardableResult attribute we won't get warnings if we
    // don't end up doing any chaining.
    @discardableResult
    public func withHeaders(_ value: Headers) -> HTTPRequestBuilder {
        self.headers.addAll(headers: value)
        return self
    }

    @discardableResult
    public func withHeader(name: String, value: String) -> HTTPRequestBuilder {
        self.headers.add(name: name, value: value)
        return self
    }

    @discardableResult
    public func updateHeader(name: String, value: String) -> HTTPRequestBuilder {
        self.headers.update(name: name, value: value)
        return self
    }

    @discardableResult
    public func updateHeader(name: String, value: [String]) -> HTTPRequestBuilder {
        self.headers.update(name: name, value: value)
        return self
    }

    @discardableResult
    public func withTrailers(_ value: Headers) -> HTTPRequestBuilder {
        self.trailingHeaders.addAll(headers: value)
        return self
    }

    @discardableResult
    public func updateTrailer(name: String, value: [String]) -> HTTPRequestBuilder {
        self.trailingHeaders.update(name: name, value: value)
        return self
    }

    @discardableResult
    public func withMethod(_ value: HTTPMethodType) -> HTTPRequestBuilder {
        self.methodType = value
        return self
    }

    @discardableResult
    public func withHost(_ value: String) -> HTTPRequestBuilder {
        self.host = value
        return self
    }

    @discardableResult
    public func withPath(_ value: String) -> HTTPRequestBuilder {
        self.path = value
        return self
    }

    @discardableResult
    public func withBody(_ value: ByteStream) -> HTTPRequestBuilder {
        self.body = value
        return self
    }

    @discardableResult
    public func withQueryItems(_ value: [URIQueryItem]) -> HTTPRequestBuilder {
        self.queryItems.append(contentsOf: value)
        return self
    }

    @discardableResult
    public func withQueryItem(_ value: URIQueryItem) -> HTTPRequestBuilder {
        withQueryItems([value])
    }

    @discardableResult
    public func replacingQueryItems(_ value: [URIQueryItem]) -> HTTPRequestBuilder {
        self.queryItems = value
        return self
    }

    @discardableResult
    public func withPort(_ value: UInt16?) -> HTTPRequestBuilder {
        self.port = value
        return self
    }

    @discardableResult
    public func withProtocol(_ value: URIScheme) -> HTTPRequestBuilder {
        self.protocolType = value
        return self
    }

    public func build() -> HTTPRequest {
        let uri = URIBuilder()
            .withScheme(protocolType)
            .withPath(path)
            .withHost(host)
            .withPort(port)
            .withQueryItems(queryItems)
            .build()
        return HTTPRequest(method: methodType, uri: uri, headers: headers, body: body)
    }
}

extension HTTPRequestBuilder {
    public var signature: String? {
        let authHeader = self.headers.value(for: "Authorization")
        guard let signatureSequence = authHeader?.split(separator: "=").last else {
            return nil
        }
        return String(signatureSequence)
    }
}

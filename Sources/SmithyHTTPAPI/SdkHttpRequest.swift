//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

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
public final class SdkHttpRequest: RequestMessage {
    public var body: ByteStream
    public let destination: URI
    public var headers: Headers
    public let method: HttpMethodType
    public var host: String { destination.host }
    public var path: String { destination.path }
    public var queryItems: [SDKURLQueryItem]? { destination.queryItems }
    public var trailingHeaders: Headers = Headers()
    public var endpoint: Endpoint {
        return Endpoint(uri: self.destination, headers: self.headers)
    }

    public convenience init(method: HttpMethodType,
                            endpoint: Endpoint,
                            body: ByteStream = ByteStream.noStream) {
        self.init(method: method, uri: endpoint.uri, headers: endpoint.headers, body: body)
    }

    public init(method: HttpMethodType,
                uri: URI,
                headers: Headers,
                body: ByteStream = ByteStream.noStream) {
        self.method = method
        self.destination = uri
        self.headers = headers
        self.body = body
    }

    public func toBuilder() -> SdkHttpRequestBuilder {
        let builder = SdkHttpRequestBuilder()
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

public extension URLRequest {
    init(sdkRequest: SdkHttpRequest) async throws {
        // Set URL
        guard let url = sdkRequest.destination.url else {
            throw ClientError.dataNotFound("Failed to construct URLRequest due to missing URL.")
        }
        self.init(url: url)
        // Set method type
        self.httpMethod = sdkRequest.method.rawValue
        // Set body, handling any serialization errors
        do {
            let data = try await sdkRequest.body.readData()
            sdkRequest.body = .data(data)
            self.httpBody = data
        } catch {
            throw ClientError.serializationFailed("Failed to construct URLRequest due to HTTP body conversion failure.")
        }
        // Set headers
        sdkRequest.headers.headers.forEach { header in
            header.value.forEach { value in
                self.addValue(value, forHTTPHeaderField: header.name)
            }
        }
    }
}

extension SdkHttpRequest: CustomDebugStringConvertible, CustomStringConvertible {

    public var debugDescriptionWithBody: String {
        return debugDescription + "\nRequestBody: \(body.debugDescription)"
    }

    public var debugDescription: String {
        description
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

public class SdkHttpRequestBuilder: RequestMessageBuilder {

    required public init() {}

<<<<<<< HEAD:Sources/SmithyHTTPAPI/SdkHttpRequest.swift
    public var headers: Headers = Headers()
    public private(set) var methodType: HttpMethodType = .get
    public private(set) var host: String = ""
    public private(set) var path: String = "/"
    public private(set) var body: ByteStream = .noStream
    public private(set) var queryItems: [SDKURLQueryItem]?
    public private(set) var port: Int16 = 443
    public private(set) var protocolType: ProtocolType = .https
    public private(set) var trailingHeaders: Headers = Headers()
=======
    var headers: Headers = Headers()
    var methodType: HttpMethodType = .get
    var host: String = ""
    var path: String = "/"
    var body: ByteStream = .noStream
    var queryItems: [SDKURLQueryItem] = []
    var port: Int16?
    var protocolType: ProtocolType = .https
    var trailingHeaders: Headers = Headers()

    public var currentQueryItems: [SDKURLQueryItem]? {
        return queryItems
    }
>>>>>>> main:Sources/ClientRuntime/Networking/Http/SdkHttpRequest.swift

    // We follow the convention of returning the builder object
    // itself from any configuration methods, and by adding the
    // @discardableResult attribute we won't get warnings if we
    // don't end up doing any chaining.
    @discardableResult
    public func withHeaders(_ value: Headers) -> SdkHttpRequestBuilder {
        self.headers.addAll(headers: value)
        return self
    }

    @discardableResult
    public func withHeader(name: String, value: String) -> SdkHttpRequestBuilder {
        self.headers.add(name: name, value: value)
        return self
    }

    @discardableResult
    public func updateHeader(name: String, value: String) -> SdkHttpRequestBuilder {
        self.headers.update(name: name, value: value)
        return self
    }

    @discardableResult
    public func updateHeader(name: String, value: [String]) -> SdkHttpRequestBuilder {
        self.headers.update(name: name, value: value)
        return self
    }

    @discardableResult
    public func withTrailers(_ value: Headers) -> SdkHttpRequestBuilder {
        self.trailingHeaders.addAll(headers: value)
        return self
    }

    @discardableResult
    public func updateTrailer(name: String, value: [String]) -> SdkHttpRequestBuilder {
        self.trailingHeaders.update(name: name, value: value)
        return self
    }

    @discardableResult
    public func withMethod(_ value: HttpMethodType) -> SdkHttpRequestBuilder {
        self.methodType = value
        return self
    }

    @discardableResult
    public func withHost(_ value: String) -> SdkHttpRequestBuilder {
        self.host = value
        return self
    }

    @discardableResult
    public func withPath(_ value: String) -> SdkHttpRequestBuilder {
        self.path = value
        return self
    }

    @discardableResult
    public func withBody(_ value: ByteStream) -> SdkHttpRequestBuilder {
        self.body = value
        return self
    }

    @discardableResult
    public func withQueryItems(_ value: [SDKURLQueryItem]) -> SdkHttpRequestBuilder {
        self.queryItems.append(contentsOf: value)
        return self
    }

    @discardableResult
    public func withQueryItem(_ value: SDKURLQueryItem) -> SdkHttpRequestBuilder {
        withQueryItems([value])
    }

    @discardableResult
<<<<<<< HEAD:Sources/SmithyHTTPAPI/SdkHttpRequest.swift
    public func replacingQueryItems(_ value: [SDKURLQueryItem]) -> SdkHttpRequestBuilder {
        self.queryItems = value
        return self
    }

    @discardableResult
    public func withPort(_ value: Int16) -> SdkHttpRequestBuilder {
=======
    public func withPort(_ value: Int16?) -> SdkHttpRequestBuilder {
>>>>>>> main:Sources/ClientRuntime/Networking/Http/SdkHttpRequest.swift
        self.port = value
        return self
    }

    @discardableResult
    public func withProtocol(_ value: ProtocolType) -> SdkHttpRequestBuilder {
        self.protocolType = value
        return self
    }

    public func build() -> SdkHttpRequest {
        let uri = URIBuilder()
            .withScheme(protocolType)
            .withPath(path)
            .withHost(host)
            .withPort(port)
            .withQueryItems(queryItems)
            .build()
        return SdkHttpRequest(method: methodType, uri: uri, headers: headers, body: body)
    }
}

extension SdkHttpRequestBuilder {
    public var signature: String? {
        let authHeader = self.headers.value(for: "Authorization")
        guard let signatureSequence = authHeader?.split(separator: "=").last else {
            return nil
        }
        return String(signatureSequence)
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime

public struct ExpectedSdkHttpRequest {
    public var body: ByteStream
    public var headers: Headers?
    public var forbiddenHeaders: [String]?
    public var requiredHeaders: [String]?
    public var queryItems: [SDKURLQueryItem] { endpoint.queryItems }
    public let forbiddenQueryItems: [SDKURLQueryItem]?
    public let requiredQueryItems: [SDKURLQueryItem]?
    public let endpoint: Endpoint
    public let method: HttpMethodType

    public init(method: HttpMethodType,
                endpoint: Endpoint,
                headers: Headers? = nil,
                forbiddenHeaders: [String]? = nil,
                requiredHeaders: [String]? = nil,
                forbiddenQueryItems: [SDKURLQueryItem]? = nil,
                requiredQueryItems: [SDKURLQueryItem]? = nil,
                body: ByteStream = ByteStream.noStream) {
        self.method = method
        self.endpoint = endpoint
        self.headers = headers
        self.forbiddenHeaders = forbiddenHeaders
        self.requiredHeaders = requiredHeaders
        self.forbiddenQueryItems = forbiddenQueryItems
        self.requiredQueryItems = requiredQueryItems
        self.body = body
    }
}

public class ExpectedSdkHttpRequestBuilder {

    public init() {}

    var headers = Headers()
    var forbiddenHeaders = [String]()
    var requiredHeaders = [String]()
    var methodType: HttpMethodType = .get
    var host: String = ""
    var path: String = "/"
    var body: ByteStream = .noStream
    var queryItems = [SDKURLQueryItem]()
    var forbiddenQueryItems = [SDKURLQueryItem]()
    var requiredQueryItems = [SDKURLQueryItem]()
    var port: Int16 = 443
    var protocolType: ProtocolType = .https

    // We follow the convention of returning the builder object
    // itself from any configuration methods, and by adding the
    // @discardableResult attribute we won't get warnings if we
    // don't end up doing any chaining.
    @discardableResult
    public func withHeader(name: String, values: [String]) -> ExpectedSdkHttpRequestBuilder {
        self.headers.add(name: name, values: values)
        return self
    }

    @discardableResult
    public func withHeader(name: String, value: String) -> ExpectedSdkHttpRequestBuilder {
        self.headers.add(name: name, value: value)
        return self
    }

    @discardableResult
    public func withRequiredHeader(name: String) -> ExpectedSdkHttpRequestBuilder {
        self.requiredHeaders.append(name)
        return self
    }

    @discardableResult
    public func withForbiddenHeader(name: String) -> ExpectedSdkHttpRequestBuilder {
        self.forbiddenHeaders.append(name)
        return self
    }

    @discardableResult
    public func withMethod(_ value: HttpMethodType) -> ExpectedSdkHttpRequestBuilder {
        self.methodType = value
        return self
    }

    @discardableResult
    public func withHost(_ value: String) -> ExpectedSdkHttpRequestBuilder {
        self.host = value
        return self
    }

    @discardableResult
    public func withPath(_ value: String) -> ExpectedSdkHttpRequestBuilder {
        self.path = value
        return self
    }

    @discardableResult
    public func withBody(_ value: ByteStream) -> ExpectedSdkHttpRequestBuilder {
        self.body = value
        return self
    }

    @discardableResult
    public func withQueryItem(_ value: SDKURLQueryItem) -> ExpectedSdkHttpRequestBuilder {
        self.queryItems.append(value)
        return self
    }

    @discardableResult
    public func withForbiddenQueryItem(_ value: SDKURLQueryItem) -> ExpectedSdkHttpRequestBuilder {
        self.forbiddenQueryItems.append(value)
        return self
    }

    @discardableResult
    public func withRequiredQueryItem(_ value: SDKURLQueryItem) -> ExpectedSdkHttpRequestBuilder {
        self.requiredQueryItems.append(value)
        return self
    }

    @discardableResult
    public func withPort(_ value: Int16) -> ExpectedSdkHttpRequestBuilder {
        self.port = value
        return self
    }

    @discardableResult
    public func withProtocol(_ value: ProtocolType) -> ExpectedSdkHttpRequestBuilder {
        self.protocolType = value
        return self
    }

    public func build() -> ExpectedSdkHttpRequest {
        let uri = URI(scheme: protocolType.rawValue, path: path, host: host, port: port, query: queryItems)
        let endpoint = Endpoint(uri: uri, protocolType: protocolType)
        let forbiddenQueryItems = !forbiddenQueryItems.isEmpty ? forbiddenQueryItems : nil
        let requiredQueryItems = !requiredQueryItems.isEmpty ? requiredQueryItems : nil

        let headers = !headers.headers.isEmpty ? headers : nil
        let forbiddenHeaders = !forbiddenHeaders.isEmpty ? forbiddenHeaders : nil
        let requiredHeaders = !requiredHeaders.isEmpty ? requiredHeaders : nil
        return ExpectedSdkHttpRequest(method: methodType,
                              endpoint: endpoint,
                              headers: headers,
                              forbiddenHeaders: forbiddenHeaders,
                              requiredHeaders: requiredHeaders,
                              forbiddenQueryItems: forbiddenQueryItems,
                              requiredQueryItems: requiredQueryItems,
                              body: body)
    }
}

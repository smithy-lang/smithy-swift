//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import ClientRuntime
	
public struct ExpectedSdkHttpRequest {
    public var body: HttpBody
    public var headers: Headers?
    public var forbiddenHeaders: [String]?
    public var requiredHeaders: [String]?
    public let queryItems: [URLQueryItem]?
    public let forbiddenQueryItems: [URLQueryItem]?
    public let requiredQueryItems: [URLQueryItem]?
    public let endpoint: Endpoint
    public let method: HttpMethodType
    
    public init(method: HttpMethodType,
                endpoint: Endpoint,
                headers: Headers? = nil,
                forbiddenHeaders: [String]? = nil,
                requiredHeaders: [String]? = nil,
                queryItems: [URLQueryItem]? = nil,
                forbiddenQueryItems: [URLQueryItem]? = nil,
                requiredQueryItems: [URLQueryItem]? = nil,
                body: HttpBody = HttpBody.none) {
        self.method = method
        self.endpoint = endpoint
        self.headers = headers
        self.forbiddenHeaders = forbiddenHeaders
        self.requiredHeaders = requiredHeaders
        self.queryItems = queryItems
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
    var body: HttpBody = .none
    var queryItems = [URLQueryItem]()
    var forbiddenQueryItems = [URLQueryItem]()
    var requiredQueryItems = [URLQueryItem]()
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
    public func withBody(_ value: HttpBody) -> ExpectedSdkHttpRequestBuilder {
        self.body = value
        return self
    }
    
    @discardableResult
    public func withQueryItem(_ value: URLQueryItem) -> ExpectedSdkHttpRequestBuilder {
        self.queryItems.append(value)
        return self
    }
    
    @discardableResult
    public func withForbiddenQueryItem(_ value: URLQueryItem) -> ExpectedSdkHttpRequestBuilder {
        self.forbiddenQueryItems.append(value)
        return self
    }
    
    @discardableResult
    public func withRequiredQueryItem(_ value: URLQueryItem) -> ExpectedSdkHttpRequestBuilder {
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
        let endpoint = Endpoint(host: host,
                                path: path,
                                port: port,
                                queryItems: queryItems,
                                protocolType: protocolType)
        let queryItems = !queryItems.isEmpty ? queryItems : nil
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
                              queryItems: queryItems,
                              forbiddenQueryItems: forbiddenQueryItems,
                              requiredQueryItems: requiredQueryItems,
                              body: body)
    }
}

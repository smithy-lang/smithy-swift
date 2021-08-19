/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import struct Foundation.URLQueryItem
import struct Foundation.URLComponents
import AwsCommonRuntimeKit

// we need to maintain a reference to this same request while we add headers
// in the CRT engine so that is why it's a class
public class SdkHttpRequest {
    public var body: HttpBody
    public var headers: Headers
    public let queryItems: [URLQueryItem]?
    public let endpoint: Endpoint
    public let method: HttpMethodType
    
    public init(method: HttpMethodType,
                endpoint: Endpoint,
                headers: Headers,
                queryItems: [URLQueryItem]? = nil,
                body: HttpBody = HttpBody.none) {
        self.method = method
        self.endpoint = endpoint
        self.headers = headers
        self.body = body
        self.queryItems = queryItems
    }
}

extension SdkHttpRequest {
    public func toHttpRequest(bufferSize: Int = 1024) -> HttpRequest {
        let httpHeaders = headers.toHttpHeaders()
        let httpRequest = HttpRequest()
        httpRequest.method = method.rawValue
        httpRequest.path = "\(endpoint.path)\(endpoint.queryItemString)"
        httpRequest.addHeaders(headers: httpHeaders)
        httpRequest.body = body.toAwsInputStream()
        return httpRequest
    }
}

extension SdkHttpRequest: CustomDebugStringConvertible, CustomStringConvertible {
    
    public var debugDescriptionWithBody: String {
        return debugDescription + "\n \(body)"
    }
    
    public var debugDescription: String {
        return "\(method.rawValue.uppercased()) \(endpoint.protocolType ?? ProtocolType.https):\(endpoint.port) \n Path: \(endpoint.path), \n \(headers) \n \(String(describing: queryItems))"
    }
    
    public var description: String {
        return "\(method.rawValue.uppercased()) \(endpoint.protocolType ?? ProtocolType.https):\(endpoint.port) \n Path: \(endpoint.path) \n \(headers) \n \(String(describing: queryItems))"
    }
}

extension SdkHttpRequestBuilder {
    public func update(from crtRequest: HttpRequest, originalRequest: SdkHttpRequest) -> SdkHttpRequestBuilder {
        headers = convertSignedHeadersToHeaders(crtRequest: crtRequest)
        methodType = originalRequest.method
        host = originalRequest.endpoint.host
        // TODO: remove extra slash if not needed
        let pathAndQueryItems = URLComponents(string: crtRequest.path ?? "/")
        path = pathAndQueryItems?.path ?? "/"
        queryItems = pathAndQueryItems?.queryItems ?? [URLQueryItem]()

        return self
    }
        
    func convertSignedHeadersToHeaders(crtRequest: HttpRequest) -> Headers {
        let httpHeaders = HttpHeaders()
        httpHeaders.addArray(headers: crtRequest.getHeaders())
        return Headers(httpHeaders: httpHeaders)
    }
}

public class SdkHttpRequestBuilder {
    
    public init() {}

    var headers: Headers = Headers()
    var methodType: HttpMethodType = .get
    var host: String = ""
    var path: String = "/"
    var body: HttpBody = .none
    var queryItems = [URLQueryItem]()
    var port: Int16 = 443
    var protocolType: ProtocolType = .https

    public var currentQueryItems: [URLQueryItem] {
        return queryItems
    }

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
    public func withBody(_ value: HttpBody) -> SdkHttpRequestBuilder {
        self.body = value
        return self
    }
    
    @discardableResult
    public func withQueryItems(_ value: [URLQueryItem]) -> SdkHttpRequestBuilder {
        self.queryItems = value
        return self
    }
    
    @discardableResult
    public func withQueryItem(_ value: URLQueryItem) -> SdkHttpRequestBuilder {
        self.queryItems.append(value)
        return self
    }
    
    @discardableResult
    public func withPort(_ value: Int16) -> SdkHttpRequestBuilder {
        self.port = value
        return self
    }
    
    @discardableResult
    public func withProtocol(_ value: ProtocolType) -> SdkHttpRequestBuilder {
        self.protocolType = value
        return self
    }

    public func build() -> SdkHttpRequest {
        let endpoint = Endpoint(host: host,
                                path: path,
                                port: port,
                                queryItems: queryItems,
                                protocolType: protocolType)
        return SdkHttpRequest(method: methodType,
                              endpoint: endpoint,
                              headers: headers,
                              queryItems: queryItems,
                              body: body)
    }
}

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
import struct Foundation.CharacterSet
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

// Create a `CharacterSet` of the characters that need not be percent encoded in the
// resulting URL.  This set consists of alphanumerics plus underscore, dash, tilde, and
// period.  Any other character should be percent-encoded when used in a path segment.
// Forward-slash is added as well because the segments have already been joined into a path.
//
// See, for URL-allowed characters:
// https://www.rfc-editor.org/rfc/rfc3986#section-2.3
private let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "/_-.~"))

extension SdkHttpRequest {
    public func toHttpRequest() throws -> HTTPRequest {
        let httpHeaders = headers.toHttpHeaders()
        let httpRequest = try HTTPRequest()
        httpRequest.method = method.rawValue
        let encodedPath = endpoint.path.addingPercentEncoding(withAllowedCharacters: allowed) ?? endpoint.path
        httpRequest.path = "\(encodedPath)\(endpoint.queryItemString)"
        httpRequest.addHeaders(headers: httpHeaders)
        httpRequest.body = HttpContent(body: body)
        return httpRequest
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
        let protocolType = endpoint.protocolType ?? ProtocolType.https
        let query = String(describing: queryItems)
        return "\(method) \(protocolType):\(endpoint.port) \n Path: \(endpoint.path) \n \(headers) \n \(query)"
    }
}

extension SdkHttpRequestBuilder {

    /// Update the builder with the values from the CRT request
    /// - Parameters:
    ///   - crtRequest: the CRT request, this can be either a `HTTPRequest` or a `HTTP2Request`
    ///   - originalRequest: the SDK request that is used to hold the original values
    /// - Returns: the builder
    public func update(from crtRequest: HTTPRequestBase, originalRequest: SdkHttpRequest) -> SdkHttpRequestBuilder {
        headers = convertSignedHeadersToHeaders(crtRequest: crtRequest)
        methodType = originalRequest.method
        host = originalRequest.endpoint.host
        if let crtRequest = crtRequest as? HTTPRequest {
            let pathAndQueryItems = URLComponents(string: crtRequest.path)
            path = pathAndQueryItems?.path ?? "/"
            queryItems = pathAndQueryItems?.percentEncodedQueryItems ?? [URLQueryItem]()
        } else if crtRequest as? HTTP2Request != nil {
            assertionFailure("HTTP2Request not supported")
        } else {
            assertionFailure("Unknown request type")
        }
        return self
    }

    func convertSignedHeadersToHeaders(crtRequest: HTTPRequestBase) -> Headers {
        return Headers(httpHeaders: crtRequest.getHeaders())
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
    public func updateHeader(name: String, value: [String]) -> SdkHttpRequestBuilder {
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

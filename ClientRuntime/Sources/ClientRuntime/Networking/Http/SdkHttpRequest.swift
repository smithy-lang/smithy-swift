/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation
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
        httpRequest.path = endpoint.path
        httpRequest.addHeaders(headers: httpHeaders)
        var awsInputStream: AwsInputStream?
        switch body {
        case .data(let data):
            if let data = data {
                let byteBuffer = ByteBuffer(data: data)
                awsInputStream = AwsInputStream(byteBuffer, byteBuffer: byteBuffer)
            }
        case .streamSource(let stream):
            let byteBuffer = ByteBuffer(size: bufferSize)
            stream.unwrap().sendData(writeTo: byteBuffer)
            awsInputStream = AwsInputStream(byteBuffer, byteBuffer: byteBuffer)
        case .none, .streamSink:
            awsInputStream = nil
        }
        if let inputStream = awsInputStream {
            httpRequest.body = inputStream
        }
        
        return httpRequest
    }
}

extension HttpRequest {
    public func toSdkRequest() -> SdkHttpRequest {
        
        let sdkHeaders = Headers(httpHeaders: headers ?? HttpHeaders())
        let sdkMethod = HttpMethodType(rawValue: method ?? "GET") ?? HttpMethodType.get
        let sdkPath = path ?? "/"
        //how do i get host information? do i need to store it to a crt request to then retrieve it?
        let sdkBody = HttpBody.data(body?.byteBuffer.toData()) //how do i know which kind of request this was, streaming and or otherwise?
        return SdkHttpRequest(method: sdkMethod, endpoint: Endpoint(host: "huh", path: sdkPath), headers: sdkHeaders, body: sdkBody)
    }
}

public class SdkHttpRequestBuilder {
    
    public init() {}

    var headers: Headers = Headers()
    var methodType: HttpMethodType = .get
    //TODO: figure out what host should be if anything?
    var host: String = ""
    var path: String = "/"
    var body: HttpBody = .none
    var queryItems = [URLQueryItem]()

    // We follow the convention of returning the builder object
    // itself from any configuration methods, and by adding the
    // @discardableResult attribute we won't get warnings if we
    // don't end up doing any chaining.
    @discardableResult
    public func withHeaders(_ value: Headers) -> SdkHttpRequestBuilder {
        self.headers = value
        return self
    }
    
    @discardableResult
    public func withHeader(name: String, value: String) -> SdkHttpRequestBuilder {
        self.headers.add(name: name, value: value)
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

    public func build() -> SdkHttpRequest {
        let endpoint = Endpoint(host: host, path: path, queryItems: queryItems)
        return SdkHttpRequest(method: methodType,
                              endpoint: endpoint,
                              headers: headers,
                              queryItems: queryItems,
                              body: body)
    }
}

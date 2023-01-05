// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// this struct implements middleware context and will serve as the context for all http middleware operations
public struct HttpContext: MiddlewareContext {
    public var attributes: Attributes
    var response: HttpResponse?
    
    public init(attributes: Attributes) {
        self.attributes = attributes
    }
    // FIXME: Move all defined keys to separate file as constants to be used elsewhere
    public func getPath() -> String {
        return attributes.get(key: AttributeKey<String>(name: "Path"))!
    }
    
    public func getMethod() -> HttpMethodType {
        return attributes.get(key: AttributeKey<HttpMethodType>(name: "Method"))!
    }
    
    public func getEncoder() -> RequestEncoder {
        return attributes.get(key: AttributeKey<RequestEncoder>(name: "Encoder"))!
    }
    
    public func getDecoder() -> ResponseDecoder {
        return attributes.get(key: AttributeKey<ResponseDecoder>(name: "Decoder"))!
    }
    
    public func getHost() -> String? {
        return attributes.get(key: AttributeKey<String>(name: "Host"))
    }
    
    public func getServiceName() -> String {
        return attributes.get(key: AttributeKey<String>(name: "ServiceName"))!
    }
    
    public func getIdempotencyTokenGenerator() -> IdempotencyTokenGenerator {
        return attributes.get(key: AttributeKey<IdempotencyTokenGenerator>(name: "IdempotencyTokenGenerator"))!
    }
    
    public func getHostPrefix() -> String? {
        return attributes.get(key: AttributeKey<String>(name: "HostPrefix"))
    }
    
    public func getLogger() -> LogAgent? {
        return attributes.get(key: AttributeKey<LogAgent>(name: "Logger"))
    }

    /// The partition ID to be used for this context.
    ///
    /// Requests made with the same partition ID will be grouped together for retry throttling purposes.
    /// If no partition ID is provided, requests will be partitioned based on the hostname.
    public func getPartitionID() -> String? {
        return attributes.get(key: AttributeKey<String>(name: "PartitionID"))
    }
}

public class HttpContextBuilder {
    
    public init() {}
    
    public var attributes: Attributes = Attributes()
    let encoder = AttributeKey<RequestEncoder>(name: "Encoder")
    let method = AttributeKey<HttpMethodType>(name: "Method")
    let path = AttributeKey<String>(name: "Path")
    let operation = AttributeKey<String>(name: "Operation")
    let host = AttributeKey<String>(name: "Host")
    let serviceName = AttributeKey<String>(name: "ServiceName")
    var response: HttpResponse = HttpResponse()
    let decoder = AttributeKey<ResponseDecoder>(name: "Decoder")
    let idempotencyTokenGenerator = AttributeKey<IdempotencyTokenGenerator>(name: "IdempotencyTokenGenerator")
    let hostPrefix = AttributeKey<String>(name: "HostPrefix")
    let logger = AttributeKey<LogAgent>(name: "Logger")
    let partitionID = AttributeKey<String>(name: "PartitionID")
    
    // We follow the convention of returning the builder object
    // itself from any configuration methods, and by adding the
    // @discardableResult attribute we won't get warnings if we
    // don't end up doing any chaining.
    @discardableResult
    public func with<T>(key: AttributeKey<T>,
                        value: T) -> HttpContextBuilder {
        self.attributes.set(key: key, value: value)
        return self
    }
    
    @discardableResult
    public func withEncoder(value: RequestEncoder) -> HttpContextBuilder {
        self.attributes.set(key: encoder, value: value)
        return self
    }
    
    @discardableResult
    public func withMethod(value: HttpMethodType) -> HttpContextBuilder {
        self.attributes.set(key: method, value: value)
        return self
    }
    
    @discardableResult
    public func withPath(value: String) -> HttpContextBuilder {
        self.attributes.set(key: path, value: value)
        return self
    }
    
    @discardableResult
    public func withHost(value: String) -> HttpContextBuilder {
        self.attributes.set(key: host, value: value)
        return self
    }
    
    @discardableResult
    public func withHostPrefix(value: String) -> HttpContextBuilder {
        self.attributes.set(key: hostPrefix, value: value)
        return self
    }
    
    @discardableResult
    public func withOperation(value: String) -> HttpContextBuilder {
        self.attributes.set(key: operation, value: value)
        return self
    }
    
    @discardableResult
    public func withServiceName(value: String) -> HttpContextBuilder {
        self.attributes.set(key: serviceName, value: value)
        return self
    }
    
    @discardableResult
    public func withDecoder(value: ResponseDecoder) -> HttpContextBuilder {
        self.attributes.set(key: decoder, value: value)
        return self
    }
    
    @discardableResult
    public func withResponse(value: HttpResponse) -> HttpContextBuilder {
        self.response = value
        return self
    }
    
    @discardableResult
    public func withIdempotencyTokenGenerator(value: IdempotencyTokenGenerator) -> HttpContextBuilder {
        self.attributes.set(key: idempotencyTokenGenerator, value: value)
        return self
    }
    
    @discardableResult
    public func withLogger(value: LogAgent) -> HttpContextBuilder {
        self.attributes.set(key: logger, value: value)
        return self
    }

    /// Sets the partition ID on the context builder.
    ///
    /// Requests made with the same partition ID will be grouped together for retry throttling purposes.
    /// If no partition ID is provided, requests will be partitioned based on the hostname.
    /// - Parameter value: The partition ID to be set on this builder, or `nil`.
    /// - Returns: `self`, after the partition ID is set as specified.
    @discardableResult
    public func withPartitionID(value: String?) -> HttpContextBuilder {
        self.attributes.set(key: partitionID, value: value)
        return self
    }
    
    public func build() -> HttpContext {
        return HttpContext(attributes: attributes)
    }
}

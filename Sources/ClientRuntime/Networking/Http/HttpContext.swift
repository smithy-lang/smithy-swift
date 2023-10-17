// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// this struct implements middleware context and will serve as the context for all http middleware operations
public class HttpContext: MiddlewareContext {
    public var attributes: Attributes
    var response: HttpResponse?

    public init(attributes: Attributes) {
        self.attributes = attributes
    }

    public func toBuilder() -> HttpContextBuilder {
        let builder = HttpContextBuilder()
        builder.attributes = self.attributes
        if let response = self.response {
            builder.response = response
        }
        return builder
    }

    public func getAuthSchemeResolver() -> AuthSchemeResolver? {
        return attributes.get(key: AttributeKeys.authSchemeResolver)
    }

    public func getAuthSchemes() -> Attributes? {
        return attributes.get(key: AttributeKeys.authSchemes)
    }

    public func getDecoder() -> ResponseDecoder {
        return attributes.get(key: AttributeKeys.decoder)!
    }

    public func getEncoder() -> RequestEncoder {
        return attributes.get(key: AttributeKeys.encoder)!
    }

    public func getHost() -> String? {
        return attributes.get(key: AttributeKeys.host)
    }

    public func getHostPrefix() -> String? {
        return attributes.get(key: AttributeKeys.hostPrefix)
    }

    public func getIdempotencyTokenGenerator() -> IdempotencyTokenGenerator {
        return attributes.get(key: AttributeKeys.idempotencyTokenGenerator)!
    }

    public func getIdentityResolvers() -> Attributes? {
        return attributes.get(key: AttributeKeys.identityResolvers)
    }

    public func getLogger() -> LogAgent? {
        return attributes.get(key: AttributeKeys.logger)
    }

    public func getMessageEncoder() -> MessageEncoder? {
        return attributes.get(key: AttributeKeys.messageEncoder)
    }

    public func getMessageSigner() -> MessageSigner? {
        return attributes.get(key: AttributeKeys.messageSigner)
    }

    public func getMethod() -> HttpMethodType {
        return attributes.get(key: AttributeKeys.method)!
    }
    
    public func getOperation() -> String? {
        return attributes.get(key: AttributeKeys.operation)
    }

    /// The partition ID to be used for this context.
    ///
    /// Requests made with the same partition ID will be grouped together for retry throttling purposes.
    /// If no partition ID is provided, requests will be partitioned based on the hostname.
    public func getPartitionID() -> String? {
        return attributes.get(key: AttributeKeys.partitionId)
    }

    public func getPath() -> String {
        return attributes.get(key: AttributeKeys.path)!
    }

    public func getSelectedAuthScheme() -> SelectedAuthScheme? {
        return attributes.get(key: AttributeKeys.selectedAuthScheme)
    }

    public func getServiceName() -> String {
        return attributes.get(key: AttributeKeys.serviceName)!
    }

    public func isBidirectionalStreamingEnabled() -> Bool {
        return attributes.get(key: AttributeKeys.bidirectionalStreaming) ?? false
    }

    /// Returns `true` if the request should use `http2` and only `http2` without falling back to `http1`
    public func shouldForceH2() -> Bool {
        return isBidirectionalStreamingEnabled()
    }
}

public class HttpContextBuilder {
    public init() {}

    public var attributes: Attributes = Attributes()
    var response: HttpResponse = HttpResponse()

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
    public func withAuthSchemeResolver(value: AuthSchemeResolver) -> HttpContextBuilder {
        self.attributes.set(key: AttributeKeys.authSchemeResolver, value: value)
        return self
    }

    @discardableResult
    public func withAuthScheme(value: AuthScheme) -> HttpContextBuilder {
        var authSchemes: Attributes = self.attributes.get(key: AttributeKeys.authSchemes) ?? Attributes()
        authSchemes.set(key: AttributeKey<AuthScheme>(name: "\(value.schemeID)"), value: value)
        self.attributes.set(key: AttributeKeys.authSchemes, value: authSchemes)
        return self
    }
    
    @discardableResult
    public func withAuthSchemes(value: [AuthScheme]) -> HttpContextBuilder {
        for scheme in value {
            self.withAuthScheme(value: scheme)
        }
        return self
    }

    @discardableResult
    public func withDecoder(value: ResponseDecoder) -> HttpContextBuilder {
        self.attributes.set(key: AttributeKeys.decoder, value: value)
        return self
    }

    @discardableResult
    public func withEncoder(value: RequestEncoder) -> HttpContextBuilder {
        self.attributes.set(key: AttributeKeys.encoder, value: value)
        return self
    }

    @discardableResult
    public func withHost(value: String) -> HttpContextBuilder {
        self.attributes.set(key: AttributeKeys.host, value: value)
        return self
    }

    @discardableResult
    public func withHostPrefix(value: String) -> HttpContextBuilder {
        self.attributes.set(key: AttributeKeys.hostPrefix, value: value)
        return self
    }

    @discardableResult
    public func withIdempotencyTokenGenerator(value: IdempotencyTokenGenerator) -> HttpContextBuilder {
        self.attributes.set(key: AttributeKeys.idempotencyTokenGenerator, value: value)
        return self
    }

    @discardableResult
    public func withIdentityResolver<T: IdentityResolver>(value: T, type: IdentityKind) -> HttpContextBuilder {
        var identityResolvers: Attributes = self.attributes.get(key: AttributeKeys.identityResolvers) ?? Attributes()
        identityResolvers.set(key: AttributeKey<any IdentityResolver>(name: "\(type)"), value: value)
        self.attributes.set(key: AttributeKeys.identityResolvers, value: identityResolvers)
        return self
    }

    @discardableResult
    public func withLogger(value: LogAgent) -> HttpContextBuilder {
        self.attributes.set(key: AttributeKeys.logger, value: value)
        return self
    }

    @discardableResult
    public func withMethod(value: HttpMethodType) -> HttpContextBuilder {
        self.attributes.set(key: AttributeKeys.method, value: value)
        return self
    }

    @discardableResult
    public func withOperation(value: String) -> HttpContextBuilder {
        self.attributes.set(key: AttributeKeys.operation, value: value)
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
        self.attributes.set(key: AttributeKeys.partitionId, value: value)
        return self
    }

    @discardableResult
    public func withPath(value: String) -> HttpContextBuilder {
        self.attributes.set(key: AttributeKeys.path, value: value)
        return self
    }

    @discardableResult
    public func withResponse(value: HttpResponse) -> HttpContextBuilder {
        self.response = value
        return self
    }

    @discardableResult
    public func withSelectedAuthScheme(value: SelectedAuthScheme) -> HttpContextBuilder {
        self.attributes.set(key: AttributeKeys.selectedAuthScheme, value: value)
        return self
    }

    @discardableResult
    public func withServiceName(value: String) -> HttpContextBuilder {
        self.attributes.set(key: AttributeKeys.serviceName, value: value)
        return self
    }

    public func build() -> HttpContext {
        return HttpContext(attributes: attributes)
    }
}

public enum AttributeKeys {
    public static let authSchemeResolver = AttributeKey<AuthSchemeResolver>(name: "AuthSchemeResolver")
    public static let authSchemes = AttributeKey<Attributes>(name: "AuthSchemes")
    public static let bidirectionalStreaming = AttributeKey<Bool>(name: "BidirectionalStreaming")
    public static let decoder = AttributeKey<ResponseDecoder>(name: "Decoder")
    public static let encoder = AttributeKey<RequestEncoder>(name: "Encoder")
    public static let host = AttributeKey<String>(name: "Host")
    public static let hostPrefix = AttributeKey<String>(name: "HostPrefix")
    public static let idempotencyTokenGenerator = AttributeKey<IdempotencyTokenGenerator>(
        name: "IdempotencyTokenGenerator"
    )
    public static let identityResolvers = AttributeKey<Attributes>(name: "IdentityResolvers")
    public static let logger = AttributeKey<LogAgent>(name: "Logger")
    public static let messageEncoder = AttributeKey<MessageEncoder>(name: "MessageEncoder")
    public static let messageSigner = AttributeKey<MessageSigner>(name: "MessageSigner")
    public static let method = AttributeKey<HttpMethodType>(name: "Method")
    public static let operation = AttributeKey<String>(name: "Operation")
    public static let partitionId = AttributeKey<String>(name: "PartitionID")
    public static let path = AttributeKey<String>(name: "Path")
    public static let selectedAuthScheme = AttributeKey<SelectedAuthScheme>(name: "SelectedAuthScheme")
    public static let serviceName = AttributeKey<String>(name: "ServiceName")
    public static let signingName = AttributeKey<String>(name: "SigningName")
    public static let signingRegion = AttributeKey<String>(name: "SigningRegion")

    // The attribute key used to store a credentials provider configured on service client config onto middleware context.
    public static let awsIdResolver = AttributeKey<any IdentityResolver>(name: "AWSIDResolver")
}

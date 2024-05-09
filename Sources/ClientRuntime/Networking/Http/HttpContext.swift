// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import struct Foundation.TimeInterval

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

    public func getChecksum() -> ChecksumAlgorithm? {
        return attributes.get(key: AttributeKeys.checksum)
    }

    public func getIsChunkedEligibleStream() -> Bool? {
        return attributes.get(key: AttributeKeys.isChunkedEligibleStream)
    }

    public func getExpiration() -> TimeInterval {
        return attributes.get(key: AttributeKeys.expiration) ?? 0
    }

    public func getFlowType() -> FlowType {
        return attributes.get(key: AttributeKeys.flowType) ?? .NORMAL
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

    public func getRegion() -> String? {
        return attributes.get(key: AttributeKeys.region)
    }

    public func getRequestSignature() -> String {
        return attributes.get(key: AttributeKeys.requestSignature)!
    }

    public func getSelectedAuthScheme() -> SelectedAuthScheme? {
        return attributes.get(key: AttributeKeys.selectedAuthScheme)
    }

    public func getServiceName() -> String {
        return attributes.get(key: AttributeKeys.serviceName)!
    }

    public func getSigningName() -> String? {
        return attributes.get(key: AttributeKeys.signingName)
    }

    public func getSigningRegion() -> String? {
        return attributes.get(key: AttributeKeys.signingRegion)
    }

    public func hasUnsignedPayloadTrait() -> Bool {
        return attributes.get(key: AttributeKeys.hasUnsignedPayloadTrait) ?? false
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
    public func withExpiration(value: TimeInterval) -> HttpContextBuilder {
        self.attributes.set(key: AttributeKeys.expiration, value: value)
        return self
    }

    @discardableResult
    public func withFlowType(value: FlowType) -> HttpContextBuilder {
        self.attributes.set(key: AttributeKeys.flowType, value: value)
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
    public func withIdentityResolver<T: IdentityResolver>(value: T, schemeID: String) -> HttpContextBuilder {
        var identityResolvers: Attributes = self.attributes.get(key: AttributeKeys.identityResolvers) ?? Attributes()
        identityResolvers.set(key: AttributeKey<any IdentityResolver>(name: schemeID), value: value)
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
    public func withRegion(value: String?) -> HttpContextBuilder {
        self.attributes.set(key: AttributeKeys.region, value: value)
        return self
    }

    @discardableResult
    public func withResponse(value: HttpResponse) -> HttpContextBuilder {
        self.response = value
        return self
    }

    /// Sets the request signature for the event stream operation
    /// - Parameter value: `String` request signature
    @discardableResult
    public func withRequestSignature(value: String) -> HttpContextBuilder {
        self.attributes.set(key: AttributeKeys.requestSignature, value: value)
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

    @discardableResult
    public func withSigningName(value: String) -> HttpContextBuilder {
        self.attributes.set(key: AttributeKeys.signingName, value: value)
        return self
    }

    @discardableResult
    public func withSigningRegion(value: String?) -> HttpContextBuilder {
        self.attributes.set(key: AttributeKeys.signingRegion, value: value)
        return self
    }

    @discardableResult
    public func withSocketTimeout(value: TimeInterval?) -> HttpContextBuilder {
        self.attributes.set(key: AttributeKeys.socketTimeout, value: value)
        return self
    }

    @discardableResult
    public func withUnsignedPayloadTrait(value: Bool) -> HttpContextBuilder {
        self.attributes.set(key: AttributeKeys.hasUnsignedPayloadTrait, value: value)
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
    public static let flowType = AttributeKey<FlowType>(name: "FlowType")
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
    public static let region = AttributeKey<String>(name: "Region")
    public static let requestSignature = AttributeKey<String>(name: "AWS_HTTP_SIGNATURE")
    public static let selectedAuthScheme = AttributeKey<SelectedAuthScheme>(name: "SelectedAuthScheme")
    public static let serviceName = AttributeKey<String>(name: "ServiceName")
    public static let signingName = AttributeKey<String>(name: "SigningName")
    public static let signingRegion = AttributeKey<String>(name: "SigningRegion")

    // Flags stored in signingProperties passed to signers for presigner customizations.
    public static let hasUnsignedPayloadTrait = AttributeKey<Bool>(name: "HasUnsignedPayloadTrait")
    public static let forceUnsignedBody = AttributeKey<Bool>(name: "ForceUnsignedBody")
    public static let expiration = AttributeKey<TimeInterval>(name: "Expiration")

    // Checksums
    public static let checksum = AttributeKey<ChecksumAlgorithm>(name: "checksum")

    // Streams
    public static let isChunkedEligibleStream = AttributeKey<Bool>(name: "isChunkedEligibleStream")

    // TTL calculation in retries.
    public static let estimatedSkew = AttributeKey<TimeInterval>(name: "EstimatedSkew")
    public static let socketTimeout = AttributeKey<TimeInterval>(name: "SocketTimeout")
}

// The type of flow the mdidleware context is being constructed for
public enum FlowType {
    case NORMAL, PRESIGN_REQUEST, PRESIGN_URL
}

extension HttpContext: HasAttributes {
    public func get<T>(key: AttributeKey<T>) -> T? {
        self.attributes.get(key: key)
    }

    public func contains<T>(key: AttributeKey<T>) -> Bool {
        self.attributes.contains(key: key)
    }

    public func set<T>(key: AttributeKey<T>, value: T?) {
        self.attributes.set(key: key, value: value)
    }

    public func remove<T>(key: AttributeKey<T>) {
        self.attributes.remove(key: key)
    }
}

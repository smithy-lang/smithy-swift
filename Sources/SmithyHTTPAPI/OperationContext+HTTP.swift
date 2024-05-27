//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.Attributes
import struct Smithy.AttributeKey
import class Smithy.Context
import class Smithy.ContextBuilder
import struct Foundation.TimeInterval

/// This extends `OperationContext` for all http middleware operations
extension Context {

    public var httpResponse: HttpResponse? {
        get { attributes.get(key: httpResponseKey) }
        set { attributes.set(key: httpResponseKey, value: newValue) }
    }

    public func getExpiration() -> TimeInterval {
        return attributes.get(key: SmithyHTTPAPIKeys.expiration) ?? 0
    }

    public func getHost() -> String? {
        return attributes.get(key: SmithyHTTPAPIKeys.host)
    }

    public func getHostPrefix() -> String? {
        return attributes.get(key: SmithyHTTPAPIKeys.hostPrefix)
    }

    public func getMethod() -> HttpMethodType {
        return attributes.get(key: SmithyHTTPAPIKeys.method)!
    }

    public func getOperation() -> String? {
        return attributes.get(key: SmithyHTTPAPIKeys.operation)
    }

    /// The partition ID to be used for this context.
    ///
    /// Requests made with the same partition ID will be grouped together for retry throttling purposes.
    /// If no partition ID is provided, requests will be partitioned based on the hostname.
    public func getPartitionID() -> String? {
        return attributes.get(key: SmithyHTTPAPIKeys.partitionId)
    }

    public func getPath() -> String {
        return attributes.get(key: SmithyHTTPAPIKeys.path)!
    }

    public func getRegion() -> String? {
        return attributes.get(key: SmithyHTTPAPIKeys.region)
    }

    public func getServiceName() -> String {
        return attributes.get(key: SmithyHTTPAPIKeys.serviceName)!
    }

    public func getSigningName() -> String? {
        return attributes.get(key: SmithyHTTPAPIKeys.signingName)
    }

    public func getSigningRegion() -> String? {
        return attributes.get(key: SmithyHTTPAPIKeys.signingRegion)
    }

    public func hasUnsignedPayloadTrait() -> Bool {
        return attributes.get(key: SmithyHTTPAPIKeys.hasUnsignedPayloadTrait) ?? false
    }

    public var isBidirectionalStreamingEnabled: Bool {
        get { attributes.get(key: bidirectionalStreamingKey) ?? false }
        set { attributes.set(key: bidirectionalStreamingKey, value: newValue) }
    }

    /// Returns `true` if the request should use `http2` and only `http2` without falling back to `http1`
    public func shouldForceH2() -> Bool {
        return isBidirectionalStreamingEnabled
    }
}

extension ContextBuilder {

    // We follow the convention of returning the builder object
    // itself from any configuration methods, and by adding the
    // @discardableResult attribute we won't get warnings if we
    // don't end up doing any chaining.
    @discardableResult
    public func with<T>(key: AttributeKey<T>, value: T) -> Self {
        self.attributes.set(key: key, value: value)
        return self
    }

    @discardableResult
    public func withExpiration(value: TimeInterval) -> Self {
        self.attributes.set(key: SmithyHTTPAPIKeys.expiration, value: value)
        return self
    }

    @discardableResult
    public func withHost(value: String) -> Self {
        self.attributes.set(key: SmithyHTTPAPIKeys.host, value: value)
        return self
    }

    @discardableResult
    public func withHostPrefix(value: String) -> Self {
        self.attributes.set(key: SmithyHTTPAPIKeys.hostPrefix, value: value)
        return self
    }

    @discardableResult
    public func withMethod(value: HttpMethodType) -> Self {
        self.attributes.set(key: SmithyHTTPAPIKeys.method, value: value)
        return self
    }

    @discardableResult
    public func withOperation(value: String) -> Self {
        self.attributes.set(key: SmithyHTTPAPIKeys.operation, value: value)
        return self
    }

    /// Sets the partition ID on the context builder.
    ///
    /// Requests made with the same partition ID will be grouped together for retry throttling purposes.
    /// If no partition ID is provided, requests will be partitioned based on the hostname.
    /// - Parameter value: The partition ID to be set on this builder, or `nil`.
    /// - Returns: `self`, after the partition ID is set as specified.
    @discardableResult
    public func withPartitionID(value: String?) -> Self {
        self.attributes.set(key: SmithyHTTPAPIKeys.partitionId, value: value)
        return self
    }

    @discardableResult
    public func withPath(value: String) -> Self {
        self.attributes.set(key: SmithyHTTPAPIKeys.path, value: value)
        return self
    }

    @discardableResult
    public func withRegion(value: String?) -> Self {
        self.attributes.set(key: SmithyHTTPAPIKeys.region, value: value)
        return self
    }

    @discardableResult
    public func withServiceName(value: String) -> Self {
        self.attributes.set(key: SmithyHTTPAPIKeys.serviceName, value: value)
        return self
    }

    @discardableResult
    public func withSigningName(value: String) -> Self {
        self.attributes.set(key: SmithyHTTPAPIKeys.signingName, value: value)
        return self
    }

    @discardableResult
    public func withSigningRegion(value: String?) -> Self {
        self.attributes.set(key: SmithyHTTPAPIKeys.signingRegion, value: value)
        return self
    }

    @discardableResult
    public func withUnsignedPayloadTrait(value: Bool) -> Self {
        self.attributes.set(key: SmithyHTTPAPIKeys.hasUnsignedPayloadTrait, value: value)
        return self
    }

    @discardableResult
    public func withBidirectionalStreamingEnabled(value: Bool) -> Self {
        self.attributes.set(key: bidirectionalStreamingKey, value: value)
        return self
    }
}

public enum SmithyHTTPAPIKeys {
    public static let host = AttributeKey<String>(name: "Host")
    public static let hostPrefix = AttributeKey<String>(name: "HostPrefix")
    public static let method = AttributeKey<HttpMethodType>(name: "Method")
    public static let operation = AttributeKey<String>(name: "Operation")
    public static let partitionId = AttributeKey<String>(name: "PartitionID")
    public static let path = AttributeKey<String>(name: "Path")
    public static let region = AttributeKey<String>(name: "Region")
    public static let serviceName = AttributeKey<String>(name: "ServiceName")
    public static let signingName = AttributeKey<String>(name: "SigningName")
    public static let signingRegion = AttributeKey<String>(name: "SigningRegion")

    // Flags stored in signingProperties passed to signers for presigner customizations.
    public static let hasUnsignedPayloadTrait = AttributeKey<Bool>(name: "HasUnsignedPayloadTrait")
    public static let forceUnsignedBody = AttributeKey<Bool>(name: "ForceUnsignedBody")
    public static let expiration = AttributeKey<TimeInterval>(name: "Expiration")
}

private let httpResponseKey = AttributeKey<HttpResponse>(name: "httpResponseKey")
private let bidirectionalStreamingKey = AttributeKey<Bool>(name: "BidirectionalStreamingKey")

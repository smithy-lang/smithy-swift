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

    public var httpResponse: HTTPResponse? {
        get { attributes.get(key: httpResponseKey) }
        set { attributes.set(key: httpResponseKey, value: newValue) }
    }

    public var expiration: TimeInterval {
        get { attributes.get(key: expirationKey) ?? 0 }
        set { attributes.set(key: expirationKey, value: newValue) }
    }

    public var host: String? {
        get { attributes.get(key: hostKey) }
        set { attributes.set(key: hostKey, value: newValue) }
    }

    public var hostPrefix: String? {
        get { attributes.get(key: hostPrefixKey) }
        set { attributes.set(key: hostPrefixKey, value: newValue) }
    }

    public var method: HTTPMethodType {
        get { attributes.get(key: methodKey) ?? .get }
        set { attributes.set(key: methodKey, value: newValue) }
    }

    public func getOperation() -> String? {
        return attributes.get(key: SmithyHTTPAPIKeys.operation)
    }

    /// The partition ID to be used for this context.
    ///
    /// Requests made with the same partition ID will be grouped together for retry throttling purposes.
    /// If no partition ID is provided, requests will be partitioned based on the hostname.
    public var partitionID: String? {
        get { attributes.get(key: partitionIDKey) }
        set { attributes.set(key: partitionIDKey, value: newValue) }
    }

    public var path: String {
        get { attributes.get(key: pathKey)! }
        set { attributes.set(key: pathKey, value: newValue) }
    }

    public func getRegion() -> String? {
        return attributes.get(key: SmithyHTTPAPIKeys.region)
    }

    public func getServiceName() -> String {
        return attributes.get(key: SmithyHTTPAPIKeys.serviceName)!
    }

    public var signingName: String? {
        get { attributes.get(key: signingNameKey) }
        set { attributes.set(key: signingNameKey, value: newValue) }
    }

    public var signingRegion: String? {
        get { attributes.get(key: signingRegionKey) }
        set { attributes.set(key: signingRegionKey, value: newValue) }
    }

    public func hasUnsignedPayloadTrait() -> Bool {
        return attributes.get(key: SmithyHTTPAPIKeys.hasUnsignedPayloadTrait) ?? false
    }

    public var isBidirectionalStreamingEnabled: Bool {
        get { attributes.get(key: isBidirectionalStreamingEnabledKey) ?? false }
        set { attributes.set(key: isBidirectionalStreamingEnabledKey, value: newValue) }
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
        self.attributes.set(key: expirationKey, value: value)
        return self
    }

    @discardableResult
    public func withHost(value: String) -> Self {
        self.attributes.set(key: hostKey, value: value)
        return self
    }

    @discardableResult
    public func withHostPrefix(value: String) -> Self {
        self.attributes.set(key: hostPrefixKey, value: value)
        return self
    }

    @discardableResult
    public func withMethod(value: HTTPMethodType) -> Self {
        self.attributes.set(key: methodKey, value: value)
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
        self.attributes.set(key: partitionIDKey, value: value)
        return self
    }

    @discardableResult
    public func withPath(value: String) -> Self {
        self.attributes.set(key: pathKey, value: value)
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
        self.attributes.set(key: signingNameKey, value: value)
        return self
    }

    @discardableResult
    public func withSigningRegion(value: String?) -> Self {
        self.attributes.set(key: signingRegionKey, value: value)
        return self
    }

    @discardableResult
    public func withUnsignedPayloadTrait(value: Bool) -> Self {
        self.attributes.set(key: SmithyHTTPAPIKeys.hasUnsignedPayloadTrait, value: value)
        return self
    }

    @discardableResult
    public func withBidirectionalStreamingEnabled(value: Bool) -> Self {
        self.attributes.set(key: isBidirectionalStreamingEnabledKey, value: value)
        return self
    }
}

public enum SmithyHTTPAPIKeys {
    public static let operation = AttributeKey<String>(name: "Operation")
    public static let region = AttributeKey<String>(name: "Region")
    public static let serviceName = AttributeKey<String>(name: "ServiceName")

    // Flags stored in signingProperties passed to signers for presigner customizations.
    public static let hasUnsignedPayloadTrait = AttributeKey<Bool>(name: "HasUnsignedPayloadTrait")
    public static let forceUnsignedBody = AttributeKey<Bool>(name: "ForceUnsignedBody")
}

private let methodKey = AttributeKey<HTTPMethodType>(name: "MethodKey")
private let hostKey = AttributeKey<String>(name: "HostKey")
private let hostPrefixKey = AttributeKey<String>(name: "HostPrefixKey")
private let httpResponseKey = AttributeKey<HTTPResponse>(name: "httpResponseKey")
private let isBidirectionalStreamingEnabledKey = AttributeKey<Bool>(name: "isBidirectionalStreamingEnabledKey")
private let partitionIDKey = AttributeKey<String>(name: "PartitionIDKey")
private let pathKey = AttributeKey<String>(name: "PathKey")
private let signingNameKey = AttributeKey<String>(name: "SigningNameKey")
private let signingRegionKey = AttributeKey<String>(name: "SigningRegionKey")
private let expirationKey = AttributeKey<TimeInterval>(name: "ExpirationKey")

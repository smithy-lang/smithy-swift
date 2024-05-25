//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyAPI.Attributes
import struct SmithyAPI.AttributeKey
import class SmithyAPI.OperationContext
import class SmithyAPI.OperationContextBuilder
import protocol SmithyEventStreamsAPI.MessageEncoder
import protocol SmithyEventStreamsAuthAPI.MessageSigner
import struct Foundation.TimeInterval

/// This extends `OperationContext` for all http middleware operations
extension OperationContext {

    public var httpResponse: HttpResponse? {
        get { attributes.get(key: httpResponseKey) }
        set { attributes.set(key: httpResponseKey, value: newValue) }
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

extension OperationContextBuilder {

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
        self.attributes.set(key: AttributeKeys.expiration, value: value)
        return self
    }

    @discardableResult
    public func withFlowType(value: FlowType) -> Self {
        self.attributes.set(key: AttributeKeys.flowType, value: value)
        return self
    }

    @discardableResult
    public func withHost(value: String) -> Self {
        self.attributes.set(key: AttributeKeys.host, value: value)
        return self
    }

    @discardableResult
    public func withHostPrefix(value: String) -> Self {
        self.attributes.set(key: AttributeKeys.hostPrefix, value: value)
        return self
    }

    @discardableResult
    public func withMethod(value: HttpMethodType) -> Self {
        self.attributes.set(key: AttributeKeys.method, value: value)
        return self
    }

    @discardableResult
    public func withOperation(value: String) -> Self {
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
    public func withPartitionID(value: String?) -> Self {
        self.attributes.set(key: AttributeKeys.partitionId, value: value)
        return self
    }

    @discardableResult
    public func withPath(value: String) -> Self {
        self.attributes.set(key: AttributeKeys.path, value: value)
        return self
    }

    @discardableResult
    public func withRegion(value: String?) -> Self {
        self.attributes.set(key: AttributeKeys.region, value: value)
        return self
    }

    @discardableResult
    public func withServiceName(value: String) -> Self {
        self.attributes.set(key: AttributeKeys.serviceName, value: value)
        return self
    }

    @discardableResult
    public func withSigningName(value: String) -> Self {
        self.attributes.set(key: AttributeKeys.signingName, value: value)
        return self
    }

    @discardableResult
    public func withSigningRegion(value: String?) -> Self {
        self.attributes.set(key: AttributeKeys.signingRegion, value: value)
        return self
    }

    @discardableResult
    public func withUnsignedPayloadTrait(value: Bool) -> Self {
        self.attributes.set(key: AttributeKeys.hasUnsignedPayloadTrait, value: value)
        return self
    }
}

public enum AttributeKeys {
    public static let bidirectionalStreaming = AttributeKey<Bool>(name: "BidirectionalStreaming")
    public static let flowType = AttributeKey<FlowType>(name: "FlowType")
    public static let host = AttributeKey<String>(name: "Host")
    public static let hostPrefix = AttributeKey<String>(name: "HostPrefix")
    public static let messageEncoder = AttributeKey<MessageEncoder>(name: "MessageEncoder")
    public static let messageSigner = AttributeKey<MessageSigner>(name: "MessageSigner")
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

// The type of flow the mdidleware context is being constructed for
public enum FlowType {
    case NORMAL, PRESIGN_REQUEST, PRESIGN_URL
}

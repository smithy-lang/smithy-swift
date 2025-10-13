//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Date
import struct Foundation.TimeInterval
import class Smithy.Context
import class Smithy.ContextBuilder
import protocol Smithy.RequestMessage
import protocol Smithy.ResponseMessage
import protocol Smithy.RequestMessageSerializer
import protocol Smithy.ResponseMessageDeserializer
import struct SmithyHTTPAuthAPI.SelectedAuthScheme
import protocol SmithyRetriesAPI.RetryStrategy
import struct SmithyRetriesAPI.RetryErrorInfo

/// Builds an Orchestrator, combining runtime components, interceptors, serializers, and deserializers.
///
/// Note: This is intended to be used within generated code, not directly.
public class OrchestratorBuilder<
    InputType,
    OutputType,
    RequestType: RequestMessage,
    ResponseType: ResponseMessage
> {
    /// A mutable container of the interceptors the orchestrator will use
    public var interceptors: Interceptors<InputType, OutputType, RequestType, ResponseType> =
        Interceptors()

    internal var attributes: Smithy.Context = Smithy.ContextBuilder().build()
    internal var serialize: (InputType, RequestType.RequestBuilderType, Context) throws -> Void = { _, _, _ in }
    internal var deserialize: ((ResponseType, Context) async throws -> OutputType)?
    internal var retryStrategy: (any RetryStrategy)?
    internal var retryErrorInfoProvider: ((Error) -> RetryErrorInfo?)?
    internal var clockSkewProvider: (ClockSkewProvider<RequestType, ResponseType>)?
    internal var telemetry: OrchestratorTelemetry?
    internal var selectAuthScheme: SelectAuthScheme?
    internal var applyEndpoint: (any ApplyEndpoint<RequestType>)?
    internal var applySigner: (any ApplySigner<RequestType>)?
    internal var executeRequest: (any ExecuteRequest<RequestType, ResponseType>)?

    public init() {}

    /// - Parameter attributes: Attributes the orchestrator will provide to runtime components
    /// - Returns: Builder
    @discardableResult
    public func attributes(_ attributes: Context) -> Self {
        self.attributes = attributes
        return self
    }

    /// - Parameter serializer: Function that performs part of request serialization
    /// - Returns: Builder
    @discardableResult
    public func serialize(
        _ serializer: @escaping (InputType, RequestType.RequestBuilderType, Context) throws -> Void
    ) -> Self {
        let serialize = self.serialize
        self.serialize = { (input, builder, attributes) in
            try serialize(input, builder, attributes)
            try serializer(input, builder, attributes)
        }
        return self
    }

    /// - Parameter serializer: Runtime component that performs part of request serialization
    /// - Returns: Builder
    @discardableResult
    public func serialize(_ serializer: some RequestMessageSerializer<InputType, RequestType>) -> Self {
        return self.serialize(serializer.apply(input:builder:attributes:))
    }

    /// - Parameter deserializer: Function that performs response deserialization
    /// - Returns: Builder
    @discardableResult
    public func deserialize(
        _ deserializer: @escaping (ResponseType, Context) async throws -> OutputType
    ) -> Self {
        self.deserialize = deserializer
        return self
    }

    /// - Parameter deserializer: Runtime component that performs response deserialization
    /// - Returns: Builder
    @discardableResult
    public func deserialize(
        _ deserializer: some ResponseMessageDeserializer<OutputType, ResponseType>
    ) -> Self {
        return self.deserialize(deserializer.deserialize(response:attributes:))
    }

    /// - Parameter retryStrategy: Runtime component that tells the orchestrator how to perform retries
    /// - Returns: Builder
    @discardableResult
    public func retryStrategy(_ retryStrategy: any RetryStrategy) -> Self {
        self.retryStrategy = retryStrategy
        return self
    }

    /// - Parameter retryErrorInfoProvider: Function that turns operation errors into RetryErrorInfo
    /// - Returns: Builder
    @discardableResult
    public func retryErrorInfoProvider(_ retryErrorInfoProvider: @escaping (Error) -> RetryErrorInfo?) -> Self {
        self.retryErrorInfoProvider = retryErrorInfoProvider
        return self
    }

    /// - Parameter clockSkewProvider: Function that turns operation errors into a clock skew value
    /// - Returns: Builder
    @discardableResult
    public func clockSkewProvider(_ clockSkewProvider: @escaping ClockSkewProvider<RequestType, ResponseType>) -> Self {
        self.clockSkewProvider = clockSkewProvider
        return self
    }

    /// - Parameter telemetry: container for telemetry
    /// - Returns: Builder
    @discardableResult
    public func telemetry(_ telemetry: OrchestratorTelemetry) -> Self {
        self.telemetry = telemetry
        return self
    }

    /// - Parameter selectAuthScheme: Runtime component that selects the auth scheme
    /// - Returns: Builder
    @discardableResult
    public func selectAuthScheme(_ selectAuthScheme: SelectAuthScheme) -> Self {
        self.selectAuthScheme = selectAuthScheme
        return self
    }

    /// - Parameter selectAuthScheme: Function that selects the auth scheme
    /// - Returns: Builder
    @discardableResult
    public func selectAuthScheme(
        _ selectAuthScheme: @escaping (Context) async throws -> SelectedAuthScheme?
    ) -> Self {
        self.selectAuthScheme = WrappedSelectAuthScheme(closure: selectAuthScheme)
        return self
    }

    /// - Parameter applyEndpoint: Runtime component that applies the endpoint to the request
    /// - Returns: Builder
    @discardableResult
    public func applyEndpoint(_ applyEndpoint: some ApplyEndpoint<RequestType>) -> Self {
        self.applyEndpoint = applyEndpoint
        return self
    }

    /// - Parameter applyEndpoint: Function that applies the endpoint to the request
    /// - Returns: Builder
    @discardableResult
    public func applyEndpoint(
        _ applyEndpoint: @escaping (RequestType, SelectedAuthScheme?, Context) async throws -> RequestType
    ) -> Self {
        self.applyEndpoint = WrappedApplyEndpoint(closure: applyEndpoint)
        return self
    }

    /// - Parameter applySigner: Runtime component that applies the signer to the request
    /// - Returns: Builder
    @discardableResult
    public func applySigner(_ applySigner: some ApplySigner<RequestType>) -> Self {
        self.applySigner = applySigner
        return self
    }

    /// - Parameter applySigner: Function that applies the signer to the request
    /// - Returns: Builder
    @discardableResult
    public func applySigner(
        _ applySigner: @escaping (RequestType, SelectedAuthScheme?, Context) async throws -> RequestType
    ) -> Self {
        self.applySigner = WrappedApplySigner(closure: applySigner)
        return self
    }

    /// - Parameter executeRequest: Runtime component that sends the request and receives the response
    /// - Returns: Builder
    @discardableResult
    public func executeRequest(
        _ executeRequest: some ExecuteRequest<RequestType, ResponseType>
    ) -> Self {
        self.executeRequest = executeRequest
        return self
    }

    /// - Parameter executeRequest: Function that sends the request and receives the response
    /// - Returns: Builder
    @discardableResult
    public func executeRequest(
        _ executeRequest: @escaping (RequestType, Context) async throws -> ResponseType
    ) -> Self {
        self.executeRequest = WrappedExecuteRequest(closure: executeRequest)
        return self
    }

    /// - Returns: Orchestrator
    public func build() -> Orchestrator<InputType, OutputType, RequestType, ResponseType> {
        return Orchestrator(builder: self)
    }
}

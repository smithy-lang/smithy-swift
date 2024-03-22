//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Type-erased, concrete interceptor.
/// 
/// This structure stores 
public struct AnyInterceptor<RequestType, ResponseType, AttributesType: HasAttributes> {
    public typealias InterceptorContextType = DefaultInterceptorContext<RequestType, ResponseType, AttributesType>
    public typealias InterceptorFn = (InterceptorContextType) async throws -> Void
    public typealias MutatingInterceptorFn = (inout InterceptorContextType) async throws -> Void

    private var readBeforeExecution: InterceptorFn
    private var modifyBeforeSerialization: MutatingInterceptorFn
    private var readBeforeSerialization: InterceptorFn
    private var readAfterSerialization: InterceptorFn
    private var modifyBeforeRetryLoop: MutatingInterceptorFn
    private var readBeforeAttempt: InterceptorFn
    private var modifyBeforeSigning: MutatingInterceptorFn
    private var readBeforeSigning: InterceptorFn
    private var readAfterSigning: InterceptorFn
    private var modifyBeforeTransmit: MutatingInterceptorFn
    private var readBeforeTransmit: InterceptorFn
    private var readAfterTransmit: InterceptorFn
    private var modifyBeforeDeserialization: MutatingInterceptorFn
    private var readBeforeDeserialization: InterceptorFn
    private var readAfterDeserialization: InterceptorFn
    private var modifyBeforeAttemptCompletion: MutatingInterceptorFn
    private var readAfterAttempt: InterceptorFn
    private var modifyBeforeCompletion: MutatingInterceptorFn
    private var readAfterExecution: InterceptorFn

    public init<I: Interceptor>(interceptor: I)
    where
        I.RequestType == RequestType,
        I.ResponseType == ResponseType,
        I.AttributesType == AttributesType {
        self.readBeforeExecution = interceptor.readBeforeExecution(context:)
        self.modifyBeforeSerialization = interceptor.modifyBeforeSerialization(context:)
        self.readBeforeSerialization = interceptor.readBeforeSerialization(context:)
        self.readAfterSerialization = interceptor.readAfterSerialization(context:)
        self.modifyBeforeRetryLoop = interceptor.modifyBeforeRetryLoop(context:)
        self.readBeforeAttempt = interceptor.readBeforeAttempt(context:)
        self.modifyBeforeSigning = interceptor.modifyBeforeSigning(context:)
        self.readBeforeSigning = interceptor.readBeforeSigning(context:)
        self.readAfterSigning = interceptor.readAfterSigning(context:)
        self.modifyBeforeTransmit = interceptor.modifyBeforeTransmit(context:)
        self.readBeforeTransmit = interceptor.readBeforeTransmit(context:)
        self.readAfterTransmit = interceptor.readAfterTransmit(context:)
        self.modifyBeforeDeserialization = interceptor.modifyBeforeDeserialization(context:)
        self.readBeforeDeserialization = interceptor.readBeforeDeserialization(context:)
        self.readAfterDeserialization = interceptor.readAfterDeserialization(context:)
        self.modifyBeforeAttemptCompletion = interceptor.modifyBeforeAttemptCompletion(context:)
        self.readAfterAttempt = interceptor.readAfterAttempt(context:)
        self.modifyBeforeCompletion = interceptor.modifyBeforeCompletion(context:)
        self.readAfterExecution = interceptor.readAfterExecution(context:)
    }

    public func readBeforeExecution(context: InterceptorContextType) async throws {
        try await self.readBeforeExecution(context)
    }
    public func modifyBeforeSerialization(context: inout InterceptorContextType) async throws {
        try await self.modifyBeforeSerialization(&context)
    }
    public func readBeforeSerialization(context: InterceptorContextType) async throws {
        try await self.readBeforeSerialization(context)
    }
    public func readAfterSerialization(context: InterceptorContextType) async throws {
        try await self.readAfterSerialization(context)
    }
    public func modifyBeforeRetryLoop(context: inout InterceptorContextType) async throws {
        try await self.modifyBeforeRetryLoop(&context)
    }
    public func readBeforeAttempt(context: InterceptorContextType) async throws {
        try await self.readBeforeAttempt(context)
    }
    public func modifyBeforeSigning(context: inout InterceptorContextType) async throws {
        try await self.modifyBeforeSigning(&context)
    }
    public func readBeforeSigning(context: InterceptorContextType) async throws {
        try await self.readBeforeSigning(context)
    }
    public func readAfterSigning(context: InterceptorContextType) async throws {
        try await self.readAfterSigning(context)
    }
    public func modifyBeforeTransmit(context: inout InterceptorContextType) async throws {
        try await self.modifyBeforeTransmit(&context)
    }
    public func readBeforeTransmit(context: InterceptorContextType) async throws {
        try await self.readBeforeTransmit(context)
    }
    public func readAfterTransmit(context: InterceptorContextType) async throws {
        try await self.readAfterTransmit(context)
    }
    public func modifyBeforeDeserialization(context: inout InterceptorContextType) async throws {
        try await self.modifyBeforeDeserialization(&context)
    }
    public func readBeforeDeserialization(context: InterceptorContextType) async throws {
        try await self.readBeforeDeserialization(context)
    }
    public func readAfterDeserialization(context: InterceptorContextType) async throws {
        try await self.readAfterDeserialization(context)
    }
    public func modifyBeforeAttemptCompletion(context: inout InterceptorContextType) async throws {
        try await self.modifyBeforeAttemptCompletion(&context)
    }
    public func readAfterAttempt(context: InterceptorContextType) async throws {
        try await self.readAfterAttempt(context)
    }
    public func modifyBeforeCompletion(context: inout InterceptorContextType) async throws {
        try await self.modifyBeforeCompletion(&context)
    }
    public func readAfterExecution(context: InterceptorContextType) async throws {
        try await self.readAfterExecution(context)
    }
}

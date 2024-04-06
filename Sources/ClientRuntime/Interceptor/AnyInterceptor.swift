//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Type-erased, concrete interceptor.
///
/// In order to have multiple interceptors hooked into a single operation, we
/// need a concrete type, not a protocol. This stores references to the closures
/// of interceptor implementations and delegates to them for each interceptor hook.
///
/// This doesn't conform to Interceptor because the stored closures accept a concrete
/// DefaultInterceptorContext, not the boxed `some InterceptorContext`, which can't be
/// used in closure types.
internal struct AnyInterceptor<
    RequestType: RequestMessage,
    ResponseType: ResponseMessage,
    AttributesType: HasAttributes
> {
    internal typealias InterceptorContextType = DefaultInterceptorContext<RequestType, ResponseType, AttributesType>
    internal typealias InterceptorFn = (InterceptorContextType) async throws -> Void

    private var readBeforeExecution: InterceptorFn?
    private var modifyBeforeSerialization: InterceptorFn?
    private var readBeforeSerialization: InterceptorFn?
    private var readAfterSerialization: InterceptorFn?
    private var modifyBeforeRetryLoop: InterceptorFn?
    private var readBeforeAttempt: InterceptorFn?
    private var modifyBeforeSigning: InterceptorFn?
    private var readBeforeSigning: InterceptorFn?
    private var readAfterSigning: InterceptorFn?
    private var modifyBeforeTransmit: InterceptorFn?
    private var readBeforeTransmit: InterceptorFn?
    private var readAfterTransmit: InterceptorFn?
    private var modifyBeforeDeserialization: InterceptorFn?
    private var readBeforeDeserialization: InterceptorFn?
    private var readAfterDeserialization: InterceptorFn?
    private var modifyBeforeAttemptCompletion: InterceptorFn?
    private var readAfterAttempt: InterceptorFn?
    private var modifyBeforeCompletion: InterceptorFn?
    private var readAfterExecution: InterceptorFn?

    internal init<I: Interceptor>(interceptor: I)
    where
        I.RequestType == RequestType,
        I.ResponseType == ResponseType,
        I.AttributesType == AttributesType
    {
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

    internal init(
        readBeforeExecution: InterceptorFn? = nil,
        modifyBeforeSerialization: InterceptorFn? = nil,
        readBeforeSerialization: InterceptorFn? = nil,
        readAfterSerialization: InterceptorFn? = nil,
        modifyBeforeRetryLoop: InterceptorFn? = nil,
        readBeforeAttempt: InterceptorFn? = nil,
        modifyBeforeSigning: InterceptorFn? = nil,
        readBeforeSigning: InterceptorFn? = nil,
        readAfterSigning: InterceptorFn? = nil,
        modifyBeforeTransmit: InterceptorFn? = nil,
        readBeforeTransmit: InterceptorFn? = nil,
        readAfterTransmit: InterceptorFn? = nil,
        modifyBeforeDeserialization: InterceptorFn? = nil,
        readBeforeDeserialization: InterceptorFn? = nil,
        readAfterDeserialization: InterceptorFn? = nil,
        modifyBeforeAttemptCompletion: InterceptorFn? = nil,
        readAfterAttempt: InterceptorFn? = nil,
        modifyBeforeCompletion: InterceptorFn? = nil,
        readAfterExecution: InterceptorFn? = nil
    ) {
        self.readBeforeExecution = readBeforeExecution
        self.modifyBeforeSerialization = modifyBeforeSerialization
        self.readBeforeSerialization = readBeforeSerialization
        self.readAfterSerialization = readAfterSerialization
        self.modifyBeforeRetryLoop = modifyBeforeRetryLoop
        self.readBeforeAttempt = readBeforeAttempt
        self.modifyBeforeSigning = modifyBeforeSigning
        self.readBeforeSigning = readBeforeSigning
        self.readAfterSigning = readAfterSigning
        self.modifyBeforeTransmit = modifyBeforeTransmit
        self.readBeforeTransmit = readBeforeTransmit
        self.readAfterTransmit = readAfterTransmit
        self.modifyBeforeDeserialization = modifyBeforeDeserialization
        self.readBeforeDeserialization = readBeforeDeserialization
        self.readAfterDeserialization = readAfterDeserialization
        self.modifyBeforeAttemptCompletion = modifyBeforeAttemptCompletion
        self.readAfterAttempt = readAfterAttempt
        self.modifyBeforeCompletion = modifyBeforeCompletion
        self.readAfterExecution = readAfterExecution
    }

    internal func readBeforeExecution(context: InterceptorContextType) async throws {
        try await self.readBeforeExecution?(context)
    }

    internal func modifyBeforeSerialization(context: InterceptorContextType) async throws {
        try await self.modifyBeforeSerialization?(context)
    }

    internal func readBeforeSerialization(context: InterceptorContextType) async throws {
        try await self.readBeforeSerialization?(context)
    }

    internal func readAfterSerialization(context: InterceptorContextType) async throws {
        try await self.readAfterSerialization?(context)
    }

    internal func modifyBeforeRetryLoop(context: InterceptorContextType) async throws {
        try await self.modifyBeforeRetryLoop?(context)
    }

    internal func readBeforeAttempt(context: InterceptorContextType) async throws {
        try await self.readBeforeAttempt?(context)
    }

    internal func modifyBeforeSigning(context: InterceptorContextType) async throws {
        try await self.modifyBeforeSigning?(context)
    }

    internal func readBeforeSigning(context: InterceptorContextType) async throws {
        try await self.readBeforeSigning?(context)
    }

    internal func readAfterSigning(context: InterceptorContextType) async throws {
        try await self.readAfterSigning?(context)
    }

    internal func modifyBeforeTransmit(context: InterceptorContextType) async throws {
        try await self.modifyBeforeTransmit?(context)
    }

    internal func readBeforeTransmit(context: InterceptorContextType) async throws {
        try await self.readBeforeTransmit?(context)
    }

    internal func readAfterTransmit(context: InterceptorContextType) async throws {
        try await self.readAfterTransmit?(context)
    }

    internal func modifyBeforeDeserialization(context: InterceptorContextType) async throws {
        try await self.modifyBeforeDeserialization?(context)
    }

    internal func readBeforeDeserialization(context: InterceptorContextType) async throws {
        try await self.readBeforeDeserialization?(context)
    }

    internal func readAfterDeserialization(context: InterceptorContextType) async throws {
        try await self.readAfterDeserialization?(context)
    }

    internal func modifyBeforeAttemptCompletion(context: InterceptorContextType) async throws {
        try await self.modifyBeforeAttemptCompletion?(context)
    }

    internal func readAfterAttempt(context: InterceptorContextType) async throws {
        try await self.readAfterAttempt?(context)
    }

    internal func modifyBeforeCompletion(context: InterceptorContextType) async throws {
        try await self.modifyBeforeCompletion?(context)
    }

    internal func readAfterExecution(context: InterceptorContextType) async throws {
        try await self.readAfterExecution?(context)
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyAPI.RequestMessage
import protocol SmithyAPI.ResponseMessage
import protocol SmithyAPI.HasAttributes

/// Container for 0 or more interceptors that supports adding concrete interceptor
/// implementations and closures that act as single-hook interceptors.
public struct Interceptors<
    InputType,
    OutputType,
    RequestType: RequestMessage,
    ResponseType: ResponseMessage,
    AttributesType: HasAttributes
> {
    internal typealias InterceptorType = AnyInterceptor<
        InputType, OutputType, RequestType, ResponseType, AttributesType
    >
    internal var interceptors: [InterceptorType] = []

    /// - Parameter interceptor: The Interceptor to add.
    public mutating func add(
        _ interceptor: any Interceptor<InputType, OutputType, RequestType, ResponseType, AttributesType>
    ) {
        self.interceptors.append(interceptor.erase())
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addReadBeforeExecution(
        _ interceptorFn: @escaping (any BeforeSerialization<InputType, AttributesType>) async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(readBeforeExecution: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addModifyBeforeSerialization(
        _ interceptorFn: @escaping (any MutableInput<InputType, AttributesType>) async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(modifyBeforeSerialization: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addReadBeforeSerialization(
        _ interceptorFn: @escaping (any BeforeSerialization<InputType, AttributesType>) async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(readBeforeSerialization: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addReadAfterSerialization(
        _ interceptorFn: @escaping (any AfterSerialization<InputType, RequestType, AttributesType>) async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(readAfterSerialization: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addModifyBeforeRetryLoop(
        _ interceptorFn: @escaping (any MutableRequest<InputType, RequestType, AttributesType>) async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(modifyBeforeRetryLoop: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addReadBeforeAttempt(
        _ interceptorFn: @escaping (any AfterSerialization<InputType, RequestType, AttributesType>) async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(readBeforeAttempt: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addModifyBeforeSigning(
        _ interceptorFn: @escaping (any MutableRequest<InputType, RequestType, AttributesType>) async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(modifyBeforeSigning: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addReadBeforeSigning(
        _ interceptorFn: @escaping (any AfterSerialization<InputType, RequestType, AttributesType>) async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(readBeforeSigning: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addReadAfterSigning(
        _ interceptorFn: @escaping (any AfterSerialization<InputType, RequestType, AttributesType>) async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(readAfterSigning: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addModifyBeforeTransmit(
        _ interceptorFn: @escaping (any MutableRequest<InputType, RequestType, AttributesType>) async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(modifyBeforeTransmit: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addReadBeforeTransmit(
        _ interceptorFn: @escaping (any AfterSerialization<InputType, RequestType, AttributesType>) async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(readBeforeTransmit: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addReadAfterTransmit(
        _ interceptorFn: @escaping (any BeforeDeserialization<InputType, RequestType, ResponseType, AttributesType>)
            async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(readAfterTransmit: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addModifyBeforeDeserialization(
        _ interceptorFn: @escaping (any MutableResponse<InputType, RequestType, ResponseType, AttributesType>)
            async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(modifyBeforeDeserialization: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addReadBeforeDeserialization(
        _ interceptorFn: @escaping (any BeforeDeserialization<InputType, RequestType, ResponseType, AttributesType>)
            async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(readBeforeDeserialization: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addReadAfterDeserialization(
        _ interceptorFn: @escaping (
            any AfterDeserialization<InputType, OutputType, RequestType, ResponseType, AttributesType>
        )
            async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(readAfterDeserialization: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addModifyBeforeAttemptCompletion(
        _ interceptorFn: @escaping (
            any MutableOutputAfterAttempt<InputType, OutputType, RequestType, ResponseType, AttributesType>
        )
            async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(modifyBeforeAttemptCompletion: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addReadAfterAttempt(
        _ interceptorFn: @escaping (any AfterAttempt<InputType, OutputType, RequestType, ResponseType, AttributesType>)
            async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(readAfterAttempt: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addModifyBeforeCompletion(
        _ interceptorFn: @escaping (
            any MutableOutputFinalization<InputType, OutputType, RequestType, ResponseType, AttributesType>
        ) async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(modifyBeforeCompletion: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addReadAfterExecution(
        _ interceptorFn: @escaping (any Finalization<InputType, OutputType, RequestType, ResponseType, AttributesType>)
            async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(readAfterExecution: interceptorFn))
    }
}

/// This extension is for the convenience of Orchestrator to call the same hook on all interceptors.
/// Note that it doesn't conform to Interceptor because it is backed by AnyInterceptor, which also
/// doesn't conform to Interceptor.
///
/// These methods throw the last error that occurred when executing a given hook, so if multiple
/// interceptors fail, only the last error is thrown. The rest are logged.
extension Interceptors {
    internal func readBeforeExecution(context: InterceptorType.InterceptorContextType) async throws {
        try await executeInterceptors(context: context) { interceptor, ctx in
            try await interceptor.readBeforeExecution(context: ctx)
        }
    }

    internal func modifyBeforeSerialization(context: InterceptorType.InterceptorContextType) async throws {
        try await executeInterceptors(context: context) { interceptor, ctx in
            try await interceptor.modifyBeforeSerialization(context: ctx)
        }
    }

    internal func readBeforeSerialization(context: InterceptorType.InterceptorContextType) async throws {
        try await executeInterceptors(context: context) { interceptor, ctx in
            try await interceptor.readBeforeSerialization(context: ctx)
        }
    }

    internal func readAfterSerialization(context: InterceptorType.InterceptorContextType) async throws {
        try await executeInterceptors(context: context) { interceptor, ctx in
            try await interceptor.readAfterSerialization(context: ctx)
        }
    }

    internal func modifyBeforeRetryLoop(context: InterceptorType.InterceptorContextType) async throws {
        try await executeInterceptors(context: context) { interceptor, ctx in
            try await interceptor.modifyBeforeRetryLoop(context: ctx)
        }
    }

    internal func readBeforeAttempt(context: InterceptorType.InterceptorContextType) async throws {
        try await executeInterceptors(context: context) { interceptor, ctx in
            try await interceptor.readBeforeAttempt(context: ctx)
        }
    }

    internal func modifyBeforeSigning(context: InterceptorType.InterceptorContextType) async throws {
        try await executeInterceptors(context: context) { interceptor, ctx in
            try await interceptor.modifyBeforeSigning(context: ctx)
        }
    }

    internal func readBeforeSigning(context: InterceptorType.InterceptorContextType) async throws {
        try await executeInterceptors(context: context) { interceptor, ctx in
            try await interceptor.readBeforeSigning(context: ctx)
        }
    }

    internal func readAfterSigning(context: InterceptorType.InterceptorContextType) async throws {
        try await executeInterceptors(context: context) { interceptor, ctx in
            try await interceptor.readAfterSigning(context: ctx)
        }
    }

    internal func modifyBeforeTransmit(context: InterceptorType.InterceptorContextType) async throws {
        try await executeInterceptors(context: context) { interceptor, ctx in
            try await interceptor.modifyBeforeTransmit(context: ctx)
        }
    }

    internal func readBeforeTransmit(context: InterceptorType.InterceptorContextType) async throws {
        try await executeInterceptors(context: context) { interceptor, ctx in
            try await interceptor.readBeforeTransmit(context: ctx)
        }
    }

    internal func readAfterTransmit(context: InterceptorType.InterceptorContextType) async throws {
        try await executeInterceptors(context: context) { interceptor, ctx in
            try await interceptor.readAfterTransmit(context: ctx)
        }
    }

    internal func modifyBeforeDeserialization(context: InterceptorType.InterceptorContextType) async throws {
        try await executeInterceptors(context: context) { interceptor, ctx in
            try await interceptor.modifyBeforeDeserialization(context: ctx)
        }
    }

    internal func readBeforeDeserialization(context: InterceptorType.InterceptorContextType) async throws {
        try await executeInterceptors(context: context) { interceptor, ctx in
            try await interceptor.readBeforeDeserialization(context: ctx)
        }
    }

    internal func readAfterDeserialization(context: InterceptorType.InterceptorContextType) async throws {
        try await executeInterceptors(context: context) { interceptor, ctx in
            try await interceptor.readAfterDeserialization(context: ctx)
        }
    }

    internal func modifyBeforeAttemptCompletion(context: InterceptorType.InterceptorContextType) async throws {
        try await executeInterceptors(context: context) { interceptor, ctx in
            try await interceptor.modifyBeforeAttemptCompletion(context: ctx)
        }
    }

    internal func readAfterAttempt(context: InterceptorType.InterceptorContextType) async throws {
        try await executeInterceptors(context: context) { interceptor, ctx in
            try await interceptor.readAfterAttempt(context: ctx)
        }
    }

    internal func modifyBeforeCompletion(context: InterceptorType.InterceptorContextType) async throws {
        try await executeInterceptors(context: context) { interceptor, ctx in
            try await interceptor.modifyBeforeCompletion(context: ctx)
        }
    }

    internal func readAfterExecution(context: InterceptorType.InterceptorContextType) async throws {
        try await executeInterceptors(context: context) { interceptor, ctx in
            try await interceptor.readAfterExecution(context: ctx)
        }
    }

    private func executeInterceptors(
        context: InterceptorType.InterceptorContextType,
        executeInterceptor: (InterceptorType, InterceptorType.InterceptorContextType) async throws -> Void
    ) async throws {
        var error: Error?
        for interceptor in interceptors {
            do {
                try await executeInterceptor(interceptor, context)
            } catch let e {
                // Log the previous error, if present
                if let error = error {
                    logError(error: error, context: context)
                }
                error = e
            }
        }
        if let error = error {
            throw error
        }
    }

    private func logError(error: Error, context: InterceptorType.InterceptorContextType) {
        guard let logger = context.getAttributes().logger else {
            return
        }
        logger.error(error.localizedDescription)
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Container for 0 or more interceptors that supports adding concrete interceptor
/// implementations and closures that act as single-hook interceptors.
public struct Interceptors<RequestType: RequestMessage, ResponseType: ResponseMessage, AttributesType: HasAttributes> {
    internal typealias InterceptorType = AnyInterceptor<RequestType, ResponseType, AttributesType>
    internal var interceptors: [InterceptorType] = []

    internal init() {}

    /// - Parameter interceptor: The Interceptor to add.
    public mutating func add(
        _ interceptor: any Interceptor<RequestType, ResponseType, AttributesType>
    ) {
        self.interceptors.append(interceptor.erase())
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addReadBeforeExecution(
        _ interceptorFn: @escaping (any BeforeSerialization<AttributesType>) async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(readBeforeExecution: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addModifyBeforeSerialization(
        _ interceptorFn: @escaping (any MutableInput<AttributesType>) async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(modifyBeforeSerialization: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addReadBeforeSerialization(
        _ interceptorFn: @escaping (any BeforeSerialization<AttributesType>) async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(readBeforeSerialization: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addReadAfterSerialization(
        _ interceptorFn: @escaping (any AfterSerialization<RequestType, AttributesType>) async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(readAfterSerialization: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addModifyBeforeRetryLoop(
        _ interceptorFn: @escaping (any MutableRequest<RequestType, AttributesType>) async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(modifyBeforeRetryLoop: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addReadBeforeAttempt(
        _ interceptorFn: @escaping (any AfterSerialization<RequestType, AttributesType>) async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(readBeforeAttempt: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addModifyBeforeSigning(
        _ interceptorFn: @escaping (any MutableRequest<RequestType, AttributesType>) async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(modifyBeforeSigning: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addReadBeforeSigning(
        _ interceptorFn: @escaping (any AfterSerialization<RequestType, AttributesType>) async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(readBeforeSigning: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addReadAfterSigning(
        _ interceptorFn: @escaping (any AfterSerialization<RequestType, AttributesType>) async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(readAfterSigning: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addModifyBeforeTransmit(
        _ interceptorFn: @escaping (any MutableRequest<RequestType, AttributesType>) async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(modifyBeforeTransmit: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addReadBeforeTransmit(
        _ interceptorFn: @escaping (any AfterSerialization<RequestType, AttributesType>) async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(readBeforeTransmit: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addReadAfterTransmit(
        _ interceptorFn: @escaping (any BeforeDeserialization<RequestType, ResponseType, AttributesType>)
            async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(readAfterTransmit: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addModifyBeforeDeserialization(
        _ interceptorFn: @escaping (any MutableResponse<RequestType, ResponseType, AttributesType>) async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(modifyBeforeDeserialization: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addReadBeforeDeserialization(
        _ interceptorFn: @escaping (any BeforeDeserialization<RequestType, ResponseType, AttributesType>)
            async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(readBeforeDeserialization: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addReadAfterDeserialization(
        _ interceptorFn: @escaping (any AfterDeserialization<RequestType, ResponseType, AttributesType>)
            async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(readAfterDeserialization: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addModifyBeforeAttemptCompletion(
        _ interceptorFn: @escaping (any MutableOutputAfterAttempt<RequestType, ResponseType, AttributesType>)
            async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(modifyBeforeAttemptCompletion: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addReadAfterAttempt(
        _ interceptorFn: @escaping (any AfterAttempt<RequestType, ResponseType, AttributesType>) async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(readAfterAttempt: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addModifyBeforeCompletion(
        _ interceptorFn: @escaping (any MutableOutputFinalization<RequestType, ResponseType, AttributesType>)
            async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(modifyBeforeCompletion: interceptorFn))
    }

    /// - Parameter interceptorFn: The closure to use as the Interceptor hook.
    public mutating func addReadAfterExecution(
        _ interceptorFn: @escaping (any Finalization<RequestType, ResponseType, AttributesType>) async throws -> Void
    ) {
        self.interceptors.append(AnyInterceptor(readAfterExecution: interceptorFn))
    }
}

/// This extension is for the convenience of Orchestrator to call the same hook on all interceptors.
/// Note that it doesn't conform to Interceptor because it is backed by AnyInterceptor, which also
/// doesn't conform to Interceptor.
///
/// These methods throw the last error that occurred when executing a given hook, so if multiple
/// interceptors fail, only the last error is thrown. The rest are logged (TODO)
extension Interceptors {
    internal func readBeforeExecution(context: InterceptorType.InterceptorContextType) async throws {
        var error: Error? = nil
        for i in interceptors {
            do {
                try await i.readBeforeExecution(context: context)
            } catch let e {
                error = e
            }
        }
        if let error = error {
            throw error
        }
    }

    internal func modifyBeforeSerialization(context: InterceptorType.InterceptorContextType) async throws {
        var error: Error? = nil
        for i in interceptors {
            do {
                try await i.modifyBeforeSerialization(context: context)
            } catch let e {
                error = e
            }
        }
        if let error = error {
            throw error
        }
    }

    internal func readBeforeSerialization(context: InterceptorType.InterceptorContextType) async throws {
        var error: Error? = nil
        for i in interceptors {
            do {
                try await i.readBeforeSerialization(context: context)
            } catch let e {
                error = e
            }
        }
        if let error = error {
            throw error
        }
    }

    internal func readAfterSerialization(context: InterceptorType.InterceptorContextType) async throws {
        var error: Error? = nil
        for i in interceptors {
            do {
                try await i.readAfterSerialization(context: context)
            } catch let e {
                error = e
            }
        }
        if let error = error {
            throw error
        }
    }

    internal func modifyBeforeRetryLoop(context: InterceptorType.InterceptorContextType) async throws {
        var error: Error? = nil
        for i in interceptors {
            do {
                try await i.modifyBeforeRetryLoop(context: context)
            } catch let e {
                error = e
            }
        }
        if let error = error {
            throw error
        }
    }

    internal func readBeforeAttempt(context: InterceptorType.InterceptorContextType) async throws {
        var error: Error? = nil
        for i in interceptors {
            do {
                try await i.readBeforeAttempt(context: context)
            } catch let e {
                error = e
            }
        }
        if let error = error {
            throw error
        }
    }

    internal func modifyBeforeSigning(context: InterceptorType.InterceptorContextType) async throws {
        var error: Error? = nil
        for i in interceptors {
            do {
                try await i.modifyBeforeSigning(context: context)
            } catch let e {
                error = e
            }
        }
        if let error = error {
            throw error
        }
    }

    internal func readBeforeSigning(context: InterceptorType.InterceptorContextType) async throws {
        var error: Error? = nil
        for i in interceptors {
            do {
                try await i.readBeforeSigning(context: context)
            } catch let e {
                error = e
            }
        }
        if let error = error {
            throw error
        }
    }

    internal func readAfterSigning(context: InterceptorType.InterceptorContextType) async throws {
        var error: Error? = nil
        for i in interceptors {
            do {
                try await i.readAfterSigning(context: context)
            } catch let e {
                error = e
            }
        }
        if let error = error {
            throw error
        }
    }

    internal func modifyBeforeTransmit(context: InterceptorType.InterceptorContextType) async throws {
        var error: Error? = nil
        for i in interceptors {
            do {
                try await i.modifyBeforeTransmit(context: context)
            } catch let e {
                error = e
            }
        }
        if let error = error {
            throw error
        }
    }

    internal func readBeforeTransmit(context: InterceptorType.InterceptorContextType) async throws {
        var error: Error? = nil
        for i in interceptors {
            do {
                try await i.readBeforeTransmit(context: context)
            } catch let e {
                error = e
            }
        }
        if let error = error {
            throw error
        }
    }

    internal func readAfterTransmit(context: InterceptorType.InterceptorContextType) async throws {
        var error: Error? = nil
        for i in interceptors {
            do {
                try await i.readAfterTransmit(context: context)
            } catch let e {
                error = e
            }
        }
        if let error = error {
            throw error
        }
    }

    internal func modifyBeforeDeserialization(context: InterceptorType.InterceptorContextType) async throws {
        var error: Error? = nil
        for i in interceptors {
            do {
                try await i.modifyBeforeDeserialization(context: context)
            } catch let e {
                error = e
            }
        }
        if let error = error {
            throw error
        }
    }

    internal func readBeforeDeserialization(context: InterceptorType.InterceptorContextType) async throws {
        var error: Error? = nil
        for i in interceptors {
            do {
                try await i.readBeforeDeserialization(context: context)
            } catch let e {
                error = e
            }
        }
        if let error = error {
            throw error
        }
    }

    internal func readAfterDeserialization(context: InterceptorType.InterceptorContextType) async throws {
        var error: Error? = nil
        for i in interceptors {
            do {
                try await i.readAfterDeserialization(context: context)
            } catch let e {
                error = e
            }
        }
        if let error = error {
            throw error
        }
    }

    internal func modifyBeforeAttemptCompletion(context: InterceptorType.InterceptorContextType) async throws {
        var error: Error? = nil
        for i in interceptors {
            do {
                try await i.modifyBeforeAttemptCompletion(context: context)
            } catch let e {
                error = e
            }
        }
        if let error = error {
            throw error
        }
    }

    internal func readAfterAttempt(context: InterceptorType.InterceptorContextType) async throws {
        var error: Error? = nil
        for i in interceptors {
            do {
                try await i.readAfterAttempt(context: context)
            } catch let e {
                error = e
            }
        }
        if let error = error {
            throw error
        }
    }

    internal func modifyBeforeCompletion(context: InterceptorType.InterceptorContextType) async throws {
        var error: Error? = nil
        for i in interceptors {
            do {
                try await i.modifyBeforeCompletion(context: context)
            } catch let e {
                error = e
            }
        }
        if let error = error {
            throw error
        }
    }

    internal func readAfterExecution(context: InterceptorType.InterceptorContextType) async throws {
        var error: Error? = nil
        for i in interceptors {
            do {
                try await i.readAfterExecution(context: context)
            } catch let e {
                error = e
            }
        }
        if let error = error {
            throw error
        }
    }
}

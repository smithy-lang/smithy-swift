//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context
import enum Smithy.ClientError
import protocol Smithy.RequestMessage
import protocol Smithy.ResponseMessage
import protocol Smithy.HasAttributes
import SmithyHTTPAPI
import protocol SmithyRetriesAPI.RetryStrategy
import struct SmithyRetriesAPI.RetryErrorInfo

/// Orchestrates operation execution
///
/// Execution performs the following steps in order:
/// 1. Interceptor.readBeforeExecution
/// 2. Interceptor.modifyBeforeSerialization
/// 3. Interceptor.readBeforeSerialization
/// 4. Serialize InputType into RequestType
/// 5. Interceptor.readAfterSerialization
/// 6. Interceptor.modifyBeforeRetryLoop
/// 7. If a RetryStrategy is present:
///     a. RetryStrategy.acquireInitialRetryToken
///     b. Copy the request (as it will be modified by subsequent steps, and we need to preserve it for retries)
///     c. Interceptor.readBeforeAttempt
///     d. Select the auth scheme
///     e. Apply the endpoint to the request
///     f. Interceptor.modifyBeforeSigning
///     g. Interceptor.readBeforeSigning
///     h. Sign the request
///     i. Interceptor.readAfterSigning
///     j. Interceptor.modifyBeforeTransmit
///     k. Interceptor.readBeforeTransmit
///     l. Send the request and receive the response
///     m. Interceptor.readAfterTransmit
///     n. Interceptor.modifyBeforeDeserialization
///     o. Interceptor.readBeforeDeserialization
///     p. Deserialize ResponseType into OutputType
///     q. Interceptor.readAfterDeserialization
///     r. Interceptor.modifyBeforeAttemptCompletion
///     s. Interceptor.readAfterAttempt
/// 8. If there was an error, try RetryStrategy.refreshTokenForRetry. If the token is refreshed, go to 7c
/// 9. RetryStrategy.recordSuccess
/// 10. Interceptor.modifyBeforeCompletion
/// 11. Interceptor.readAfterExecution
/// 12. If there was an error, throw it. Otherwise return the operation output
///
/// Error behavior works as follows:
/// - If any Interceptors fail, the last error is stored and the rest are logged, meaning the last error that occurred will be thrown
/// - If the service response is deserialized as an error, it is stored as an error
/// - If an error occurs in steps 1 - 7b, store the error and go straight to 10
/// - If an error occurs in steps 7c - 7q, store the error and go straight to 7r
/// - If an error occurs in step 7r, store the error and go to 7s
/// - If an error occurs in step 7s, store the error and go to 8
/// - If an error occurs in step 10, store the error and go to 11
/// - If an error occurs in step 11, store the error and go to 12
public struct Orchestrator<
    InputType,
    OutputType,
    RequestType: RequestMessage,
    ResponseType: ResponseMessage
> {
    internal typealias InterceptorContextType = DefaultInterceptorContext<
        InputType, OutputType, RequestType, ResponseType, Context
    >

    private let interceptors: Interceptors<InputType, OutputType, RequestType, ResponseType, Context>
    private let attributes: Context
    private let serialize: (InputType, RequestType.RequestBuilderType, Context) throws -> Void
    private let deserialize: (ResponseType, Context) async throws -> Result<OutputType, Error>
    private let retryStrategy: (any RetryStrategy)?
    private let retryErrorInfoProvider: (Error) -> RetryErrorInfo?
    private let selectAuthScheme: any SelectAuthScheme<Context>
    private let applyEndpoint: any ApplyEndpoint<RequestType, Context>
    private let applySigner: any ApplySigner<RequestType, Context>
    private let executeRequest: any ExecuteRequest<RequestType, ResponseType, Context>

    internal init(builder: OrchestratorBuilder<InputType, OutputType, RequestType, ResponseType>) {
        self.interceptors = builder.interceptors
        self.attributes = builder.attributes!
        self.serialize = builder.serialize
        self.deserialize = builder.deserialize!
        self.retryStrategy = builder.retryStrategy

        if let retryErrorInfoProvider = builder.retryErrorInfoProvider {
            self.retryErrorInfoProvider = retryErrorInfoProvider
        } else {
            self.retryErrorInfoProvider = { _ in nil }
        }

        if let selectAuthScheme = builder.selectAuthScheme {
            self.selectAuthScheme = selectAuthScheme
        } else {
            self.selectAuthScheme = WrappedSelectAuthScheme { _ in nil }
        }

        if let applyEndpoint = builder.applyEndpoint {
            self.applyEndpoint = applyEndpoint
        } else {
            self.applyEndpoint = WrappedApplyEndpoint { request, _, _ in request }
        }

        if let applySigner = builder.applySigner {
            self.applySigner = applySigner
        } else {
            self.applySigner = WrappedApplySigner { request, _, _ in request }
        }

        self.executeRequest = builder.executeRequest!
    }

    /// Executes the operation until just before the request would be sent, and returns the request.
    ///
    /// Unlike execute, there's no specific error behavior here. Errors are thrown from where they
    /// occur (although interceptors still throw the last error, and log the rest).
    ///
    /// - Parameter input: Operation input
    /// - Returns: Presigned request
    public func presignRequest(input: InputType) async throws -> RequestType {
        let context = DefaultInterceptorContext<InputType, OutputType, RequestType, ResponseType, Context>(
            input: input,
            attributes: attributes
        )

        try await interceptors.readBeforeExecution(context: context)
        try await interceptors.modifyBeforeSerialization(context: context)
        try await interceptors.readBeforeSerialization(context: context)

        let finalizedInput = context.getInput()
        let builder = RequestType.RequestBuilderType()
        try serialize(finalizedInput, builder, context.getAttributes())
        context.updateRequest(updated: builder.build())

        try await interceptors.readAfterSerialization(context: context)
        try await interceptors.modifyBeforeRetryLoop(context: context)
        try await interceptors.readBeforeAttempt(context: context)

        let selectedAuthScheme = try await selectAuthScheme.select(attributes: context.getAttributes())
        let withEndpoint = try await applyEndpoint.apply(
            request: context.getRequest(),
            selectedAuthScheme: selectedAuthScheme,
            attributes: context.getAttributes()
        )
        context.updateRequest(updated: withEndpoint)

        try await interceptors.modifyBeforeSigning(context: context)
        try await interceptors.readBeforeSigning(context: context)

        let signed = try await applySigner.apply(
            request: context.getRequest(),
            selectedAuthScheme: selectedAuthScheme,
            attributes: context.getAttributes()
        )
        context.updateRequest(updated: signed)

        try await interceptors.readAfterSigning(context: context)
        try await interceptors.modifyBeforeTransmit(context: context)
        try await interceptors.readBeforeTransmit(context: context)

        return context.getRequest()
    }

    /// Executes the operation.
    ///
    /// - Parameter input: Operation input
    /// - Returns: Operation output
    public func execute(input: InputType) async throws -> OutputType {
        let context = DefaultInterceptorContext<InputType, OutputType, RequestType, ResponseType, Context>(
            input: input,
            attributes: attributes
        )

        do {
            try await interceptors.readBeforeExecution(context: context)
            try await interceptors.modifyBeforeSerialization(context: context)
            try await interceptors.readBeforeSerialization(context: context)

            let finalizedInput = context.getInput()
            let builder = RequestType.RequestBuilderType()
            try serialize(finalizedInput, builder, context.getAttributes())
            context.updateRequest(updated: builder.build())

            try await interceptors.readAfterSerialization(context: context)
            try await interceptors.modifyBeforeRetryLoop(context: context)

            // Skip retries if a strategy wasn't provided
            if let retryStrategy = self.retryStrategy {
                try await enterRetryLoop(context: context, strategy: retryStrategy)
            } else {
                await attempt(context: context)
            }
        } catch let error {
            context.updateResult(updated: .failure(error))
        }

        return try await startCompletion(context: context)
    }

    private func enterRetryLoop(context: InterceptorContextType, strategy: some RetryStrategy) async throws {
        let partitionId = try getPartitionId(context: context)
        let token = try await strategy.acquireInitialRetryToken(tokenScope: partitionId)
        await startAttempt(context: context, strategy: strategy, token: token)
    }

    private func getPartitionId(context: InterceptorContextType) throws -> String {
        if let customId = context.getAttributes().partitionID, !customId.isEmpty {
            return customId
        } else if !context.getRequest().host.isEmpty {
            return context.getRequest().host
        } else {
            throw ClientError.unknownError("Retry partition ID could not be determined")
        }
    }

    private func startAttempt<S: RetryStrategy>(
        context: InterceptorContextType,
        strategy: S,
        token: S.Token
    ) async {
        let copiedRequest = context.getRequest().toBuilder().build()

        await attempt(context: context)

        if case let .failure(error) = context.getResult() {
            // If we can't get errorInfo, we definitely can't retry
            guard let errorInfo = retryErrorInfoProvider(error) else { return }

            // When refreshing fails it throws, indicating we're done retrying
            do {
                try await strategy.refreshRetryTokenForRetry(tokenToRenew: token, errorInfo: errorInfo)
            } catch {
                return
            }

            context.updateRequest(updated: copiedRequest)
            await startAttempt(context: context, strategy: strategy, token: token)
        } else {
            await strategy.recordSuccess(token: token)
        }
    }

    private func attempt(context: InterceptorContextType) async {
        // If anything in here fails, the attempt short-circuits and we go to modifyBeforeAttemptCompletion,
        // with the thrown error in context.result
        do {
            try await interceptors.readBeforeAttempt(context: context)

            let selectedAuthScheme = try await selectAuthScheme.select(attributes: context.getAttributes())
            let withEndpoint = try await applyEndpoint.apply(
                request: context.getRequest(),
                selectedAuthScheme: selectedAuthScheme,
                attributes: context.getAttributes()
            )
            context.updateRequest(updated: withEndpoint)

            try await interceptors.modifyBeforeSigning(context: context)
            try await interceptors.readBeforeSigning(context: context)

            let signed = try await applySigner.apply(
                request: context.getRequest(),
                selectedAuthScheme: selectedAuthScheme,
                attributes: context.getAttributes()
            )
            context.updateRequest(updated: signed)

            try await interceptors.readAfterSigning(context: context)
            try await interceptors.modifyBeforeTransmit(context: context)
            try await interceptors.readBeforeTransmit(context: context)

            let response = try await executeRequest.execute(
                request: context.getRequest(),
                attributes: context.getAttributes()
            )
            context.updateResponse(updated: response)

            try await interceptors.readAfterTransmit(context: context)
            try await interceptors.modifyBeforeDeserialization(context: context)
            try await interceptors.readBeforeDeserialization(context: context)

            let result = try await deserialize(context.getResponse(), context.getAttributes())
            // Note: can't just directly pass 'result' to 'updateResult' because of variance:
            //  i.e. Result<OutputType, _> isn't a subtype of Result<Any, _> in swift.
            switch result {
            case let .success(output):
                context.updateResult(updated: .success(output))
            case let .failure(error):
                context.updateResult(updated: .failure(error))
            }

            try await interceptors.readAfterDeserialization(context: context)
        } catch let error {
            context.updateResult(updated: .failure(error))
        }

        // If modifyBeforeAttemptCompletion fails, we still want to let readAfterAttempt run
        do {
            try await interceptors.modifyBeforeAttemptCompletion(context: context)
        } catch let error {
            context.updateResult(updated: .failure(error))
        }
        do {
            try await interceptors.readAfterAttempt(context: context)
        } catch let error {
            context.updateResult(updated: .failure(error))
        }
    }

    private func startCompletion(context: InterceptorContextType) async throws -> OutputType {
        // If modifyBeforeCompletion fails, we still want to let readAfterExecution run
        do {
            try await interceptors.modifyBeforeCompletion(context: context)
        } catch let error {
            context.updateResult(updated: .failure(error))
        }
        do {
            try await interceptors.readAfterExecution(context: context)
        } catch let error {
            context.updateResult(updated: .failure(error))
        }

        // The last error that occurred, if any, is thrown
        switch context.getResult() {
        case let .success(output):
            return output
        case let .failure(error):
            throw error
        }
    }
}

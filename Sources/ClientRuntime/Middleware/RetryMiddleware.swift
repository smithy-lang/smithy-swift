//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct RetryMiddleware<Strategy: RetryStrategy, ErrorInfoProvider: RetryErrorInfoProvider,
    Output: HttpResponseBinding, OutputError: HttpResponseErrorBinding>: Middleware {

    public var id = "Retry"

    public let strategy: Strategy

    public init(options: RetryStrategyOptions) {
        self.strategy = Strategy(options: options)
    }

    public func handle<H>(
        context: Context,
        input: SdkHttpRequestBuilder,
        next: H
    ) async throws -> OperationOutput<Output> where
        H: Handler,
        Self.MInput == H.Input,
        Self.MOutput == H.Output,
        Self.Context == H.Context {

        // Select a partition ID to be used for throttling retry requests.  Requests with the
        // same partition ID will be "pooled" together for throttling purposes.
        let partitionID: String
        if let customPartitionID = context.getPartitionID(), !customPartitionID.isEmpty {
            // use custom partition ID provided by context
            partitionID = customPartitionID
        } else if !input.host.isEmpty {
            // fall back to the hostname for partition ID, which is a "commonsense" default
            partitionID = input.host
        } else {
            throw ClientError.unknownError("Partition ID could not be determined")
        }

        do {
            let token = try await strategy.acquireInitialRetryToken(tokenScope: partitionID)
            return try await tryRequest(
                token: token,
                partitionID: partitionID,
                context: context,
                input: input,
                next: next
            )
        }
    }

    private func tryRequest<H>(
        token: Strategy.Token,
        errorType: RetryErrorType? = nil,
        partitionID: String,
        context: Context,
        input: SdkHttpRequestBuilder,
        next: H
    ) async throws -> OperationOutput<Output> where
        H: Handler,
        Self.MInput == H.Input,
        Self.MOutput == H.Output,
        Self.Context == H.Context {

        do {
            let serviceResponse = try await next.handle(context: context, input: input)
            await strategy.recordSuccess(token: token)
            return serviceResponse
        } catch let operationError {
            guard let errorInfo = ErrorInfoProvider.errorInfo(for: operationError) else { throw operationError }
            do {
                try await strategy.refreshRetryTokenForRetry(tokenToRenew: token, errorInfo: errorInfo)
            } catch {
                // TODO: log token error here
                throw operationError
            }
            return try await tryRequest(
                token: token,
                partitionID: partitionID,
                context: context,
                input: input,
                next: next
            )
        }
    }

    public typealias MInput = SdkHttpRequestBuilder
    public typealias MOutput = OperationOutput<Output>
    public typealias Context = HttpContext
}

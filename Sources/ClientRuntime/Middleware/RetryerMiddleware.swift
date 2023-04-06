//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct RetryerMiddleware<Output: HttpResponseBinding,
                                OutputError: HttpResponseBinding & ServiceErrorProviding>: Middleware {

    public var id: String = "Retryer"

    public let retryStrategy: RetryStrategy
    public let retryErrorClassifier: RetryErrorClassifying

    public init(retryStrategy: RetryStrategy, retryErrorClassifier: RetryErrorClassifying) {
        self.retryStrategy = retryStrategy
        self.retryErrorClassifier = retryErrorClassifier
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
            throw SdkError<OutputError>.client(ClientError.unknownError("Partition ID could not be determined"))
        }

        do {
            let token = try await retryStrategy.acquireInitialRetryToken(tokenScope: partitionID)
            return try await tryRequest(
                token: token,
                partitionID: partitionID,
                context: context,
                input: input,
                next: next
            )
        } catch {
            throw SdkError<OutputError>.client(ClientError.retryError(error))
        }
    }

    func tryRequest<H>(
        token: RetryToken,
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
            retryStrategy.recordSuccess(token: token)
            return serviceResponse
        } catch let error as SdkError<OutputError> {
            guard let errorInfo = retryErrorClassifier.retryErrorInfo(error: error) else { throw error }
            let newToken = try await retryStrategy.refreshRetryTokenForRetry(tokenToRenew: token, errorInfo: errorInfo)
            // TODO: rewind the stream once streaming is properly implemented
            return try await tryRequest(
                token: newToken,
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

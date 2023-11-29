//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct RetryMiddleware<Strategy: RetryStrategy,
                              ErrorInfoProvider: RetryErrorInfoProvider,
                              Output>: Middleware {

    public typealias MInput = SdkHttpRequestBuilder
    public typealias MOutput = OperationOutput<Output>
    public typealias Context = HttpContext

    public var id: String { "Retry" }
    public var strategy: Strategy

    public init(options: RetryStrategyOptions) {
        self.strategy = Strategy(options: options)
    }

    public func handle<H>(context: Context, input: SdkHttpRequestBuilder, next: H) async throws ->
        OperationOutput<Output> where H: Handler, MInput == H.Input, MOutput == H.Output, Context == H.Context {

        let partitionID = try getPartitionID(context: context, input: input)
        let token = try await strategy.acquireInitialRetryToken(tokenScope: partitionID)
        return try await sendRequest(token: token, context: context, input: input, next: next)
    }

    private func sendRequest<H>(token: Strategy.Token, context: Context, input: MInput, next: H) async throws ->
        OperationOutput<Output> where H: Handler, MInput == H.Input, MOutput == H.Output, Context == H.Context {

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
            return try await sendRequest(token: token, context: context, input: input, next: next)
        }
    }

    private func getPartitionID(context: Context, input: MInput) throws -> String {
        // Select a partition ID to be used for throttling retry requests.  Requests with the
        // same partition ID will be "pooled" together for throttling purposes.
        //
        // This will be revisited when standard architecture for DNS is implemented, since
        // partitions may be set based on IPs in certain circumstances.
        if let customPartitionID = context.getPartitionID(), !customPartitionID.isEmpty {
            // use custom partition ID provided by context
            return customPartitionID
        } else if !input.host.isEmpty {
            // fall back to the hostname for partition ID, which is a "commonsense" default
            return input.host
        } else {
            throw ClientError.unknownError("Partition ID could not be determined")
        }
    }
}

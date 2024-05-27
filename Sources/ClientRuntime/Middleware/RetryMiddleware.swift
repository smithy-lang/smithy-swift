//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Context
import enum Smithy.ClientError
import class Foundation.DateFormatter
import struct Foundation.Locale
import struct Foundation.TimeInterval
import struct Foundation.TimeZone
import struct Foundation.UUID
import protocol SmithyRetriesAPI.RetryStrategy
import protocol SmithyRetriesAPI.RetryErrorInfoProvider
import struct SmithyRetriesAPI.RetryStrategyOptions
import SmithyHTTPAPI

public struct RetryMiddleware<Strategy: RetryStrategy,
                              ErrorInfoProvider: RetryErrorInfoProvider,
                              OperationStackOutput>: Middleware {

    public typealias MInput = SdkHttpRequestBuilder
    public typealias MOutput = OperationOutput<OperationStackOutput>

    public var id: String { "Retry" }
    public var strategy: Strategy

    // The UUID string used to uniquely identify an API call and all of its subsequent retries.
    private let invocationID = UUID().uuidString.lowercased()
    // Max number of retries configured for retry strategy.
    private var maxRetries: Int

    public init(options: RetryStrategyOptions) {
        self.strategy = Strategy(options: options)
        self.maxRetries = options.maxRetriesBase
    }

    public func handle<H>(context: Context, input: SdkHttpRequestBuilder, next: H) async throws ->
        OperationOutput<OperationStackOutput>
        where H: Handler, MInput == H.Input, MOutput == H.Output {

        input.withHeader(name: "amz-sdk-invocation-id", value: invocationID)

        let partitionID = try getPartitionID(context: context, input: input)
        let token = try await strategy.acquireInitialRetryToken(tokenScope: partitionID)
        input.withHeader(name: "amz-sdk-request", value: "attempt=1; max=\(maxRetries)")
        return try await sendRequest(attemptNumber: 1, token: token, context: context, input: input, next: next)
    }

    private func sendRequest<H>(
        attemptNumber: Int,
        token: Strategy.Token,
        context: Context,
        input: MInput, next: H
    ) async throws ->
        OperationOutput<OperationStackOutput>
        where H: Handler, MInput == H.Input, MOutput == H.Output {
        do {
            let serviceResponse = try await next.handle(context: context, input: input)
            await strategy.recordSuccess(token: token)
            return serviceResponse
        } catch let operationError {
            guard let errorInfo = ErrorInfoProvider.errorInfo(for: operationError) else { throw operationError }
            do {
                try await strategy.refreshRetryTokenForRetry(tokenToRenew: token, errorInfo: errorInfo)
            } catch {
                context.getLogger()?.error("Failed to refresh retry token: \(errorInfo.errorType)")
                throw operationError
            }
            var estimatedSkew = context.estimatedSkew ?? {
                context.getLogger()?.info("Estimated skew not found; defaulting to zero.")
                return 0
            }()
            var socketTimeout = context.socketTimeout ?? {
                context.getLogger()?.info("Socket timeout value not found; defaulting to 60 seconds.")
                return 60.0
            }()
            let ttlDateUTCString = getTTL(now: Date(), estimatedSkew: estimatedSkew, socketTimeout: socketTimeout)
            input.updateHeader(
                name: "amz-sdk-request",
                value: "ttl=\(ttlDateUTCString); attempt=\(attemptNumber + 1); max=\(maxRetries)"
            )
            return try await sendRequest(
                attemptNumber: attemptNumber + 1,
                token: token,
                context: context,
                input: input,
                next: next
            )
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

// Calculates & returns TTL datetime in strftime format `YYYYmmddTHHMMSSZ`.
func getTTL(now: Date, estimatedSkew: TimeInterval, socketTimeout: TimeInterval) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyyMMdd'T'HHmmss'Z'"
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    let ttlDate = now.addingTimeInterval(estimatedSkew + socketTimeout)
    return dateFormatter.string(from: ttlDate)
}

// Calculates & returns estimated skew.
func getEstimatedSkew(now: Date, responseDateString: String) -> TimeInterval {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
    let responseDate: Date = dateFormatter.date(from: responseDateString) ?? now
    // (Estimated skew) = (Date header from HTTP response) - (client's current time)).
    return responseDate.timeIntervalSince(now)
}

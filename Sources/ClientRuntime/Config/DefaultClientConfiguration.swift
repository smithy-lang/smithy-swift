//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol DefaultClientConfiguration: ClientConfiguration {
    /// The logger to be used for client activity.
    ///
    /// If none is provided, the SDK's logger will be used.
    var logger: LogAgent { get set }

    /// The configuration for retry of failed network requests.
    ///
    /// Default options are provided if none are set.
    var retryStrategyOptions: RetryStrategyOptions { get set }

    /// The log mode to use for client logging.
    ///
    /// If none is provided, `.request` will be used.
    var clientLogMode: ClientLogMode { get set }

    /// The network endpoint to use.
    ///
    /// If none is provided, the service will select its own endpoint to use.
    var endpoint: String? { get set }

    /// A token generator to ensure idempotency of requests.
    var idempotencyTokenGenerator: IdempotencyTokenGenerator { get set }

    /// TODO(plugins): Add Checksum, Traceprobes, etc.
}

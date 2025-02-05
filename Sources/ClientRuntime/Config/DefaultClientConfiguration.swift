//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct SmithyRetriesAPI.RetryStrategyOptions

public protocol DefaultClientConfiguration: ClientConfiguration {
    /// The configuration for retry of failed network requests.
    ///
    /// Default options are used if none are set.
    var retryStrategyOptions: RetryStrategyOptions { get set }

    /// The log mode to use for request / response messages.
    ///
    /// If none is provided, `.none` will be used.
    var clientLogMode: ClientLogMode { get set }

    /// The network endpoint to use.
    ///
    /// If none is provided, the service will select its own endpoint to use.
    var endpoint: String? { get set }

    /// A token generator to ensure idempotency of requests.
    var idempotencyTokenGenerator: IdempotencyTokenGenerator { get set }

    /// Configuration for telemetry, including tracing, metrics, and logging.
    ///
    /// If none is provided, only a default logger provider will be used.
    var telemetryProvider: TelemetryProvider { get set }

    /// TODO(plugins): Add Checksum, etc.
}

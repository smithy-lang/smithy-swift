//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol Smithy.LogAgent
import struct SmithyRetriesAPI.RetryStrategyOptions

public protocol DefaultClientConfiguration: ClientConfiguration {

    /// The configuration for retry of failed network requests.
    ///
    /// Default options are used if none are set.
    var retryStrategyOptions: RetryStrategyOptions { get }

    /// The LogAgent to be used when logging messages related to API calls.
    var logger: LogAgent { get }

    /// The log mode to use for request / response messages.
    ///
    /// If none is provided, `.none` will be used.
    var clientLogMode: ClientLogMode { get }

    /// The network endpoint to use.
    ///
    /// If none is provided, the service will select its own endpoint to use.
    var endpoint: String? { get }

    /// A token generator to ensure idempotency of requests.
    var idempotencyTokenGenerator: IdempotencyTokenGenerator { get }

    /// Configuration for telemetry, including tracing, metrics, and logging.
    ///
    /// If none is provided, only a default logger provider will be used.
    var telemetryProvider: TelemetryProvider { get }

    /// TODO(plugins): Add Checksum, etc.
}

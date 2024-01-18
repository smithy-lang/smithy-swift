//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol DefaultClientConfiguration {
    /// The custom encoder to be used for encoding models for transmission.
    ///
    /// If no encoder is provided, one will be provided by the SDK.
    var encoder: RequestEncoder? { get set }

    /// The custom decoder to be used for decoding models from a response.
    ///
    /// If no decoder is provided, one will be provided by the SDK.
    var decoder: ResponseDecoder? { get set }

    /// The HTTP client to be used for SDK HTTP requests.
    ///
    /// If none is provided, AWS SDK for Swift selects its own HTTP client for use:
    /// - On Mac and Linux, a AWS-provided HTTP client is used for the best stability and performance with heavy AWS workloads.
    /// - On iOS, tvOS, watchOS, and visionOS, a `URLSession`-based client is used for maximum compatibility and performance on Apple devices.
    var httpClientEngine: HTTPClient { get set }

    /// Configuration for the HTTP client.
    var httpClientConfiguration: HttpClientConfiguration { get set }

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

    /// TODO: Add Checksum, Traceprobs,
}

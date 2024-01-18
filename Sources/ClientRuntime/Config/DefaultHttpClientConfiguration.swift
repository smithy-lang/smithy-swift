//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol DefaultHttpClientConfiguration {

    /// The HTTP client to be used for SDK HTTP requests.
    ///
    /// If none is provided, AWS SDK for Swift selects its own HTTP client for use:
    /// - On Mac and Linux, a AWS-provided HTTP client is used for the best stability and performance with heavy AWS workloads.
    /// - On iOS, tvOS, watchOS, and visionOS, a `URLSession`-based client is used for maximum compatibility and performance on Apple devices.
    var httpClientEngine: HTTPClient { get set }

    /// Configuration for the HTTP client.
    var httpClientConfiguration: HttpClientConfiguration { get set }

    /// TODO: Add auth scheme
}

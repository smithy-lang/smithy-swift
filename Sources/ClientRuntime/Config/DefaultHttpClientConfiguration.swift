//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol DefaultHttpClientConfiguration: ClientConfiguration {

    /// The HTTP client to be used for the target platform, configured with the supplied configuration.
    ///
    /// By default, Swift SDK will set this to `CRTClientEngine` client on Mac & Linux platforms,
    /// or `URLSessionHttpClient` on non-Mac Apple platforms.
    var httpClientEngine: HTTPClient { get set }

    /// Configuration for the HTTP client.
    var httpClientConfiguration: HttpClientConfiguration { get }

    /// TODO: Add auth scheme
}

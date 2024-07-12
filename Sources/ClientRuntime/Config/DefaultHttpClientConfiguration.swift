//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyHTTPAPI.HTTPClient
import protocol SmithyHTTPAuthAPI.AuthScheme
import protocol SmithyHTTPAuthAPI.AuthSchemeResolver
import protocol SmithyIdentity.BearerTokenIdentityResolver

public protocol DefaultHttpClientConfiguration: ClientConfiguration {

    /// The HTTP client to be used for the target platform, configured with the supplied configuration.
    ///
    /// By default, Swift SDK will set this to `CRTClientEngine` client on Mac & Linux platforms,
    /// or `URLSessionHttpClient` on non-Mac Apple platforms.
    var httpClientEngine: HTTPClient { get set }

    /// Configuration for the HTTP client.
    var httpClientConfiguration: HttpClientConfiguration { get set }

    /// List of auth schemes to use for client calls.
    ///
    /// Defaults to auth schemes defined on the Smithy service model.
    var authSchemes: [AuthScheme]? { get set }

    /// The auth scheme resolver to use for resolving auth scheme.
    ///
    /// Defaults to a auth scheme resolver generated based on Smithy service model.
    var authSchemeResolver: AuthSchemeResolver { get set }

    /// The token identity resolver to be used for bearer token authentication.
    ///
    /// If no resolver is supplied, the SDK will look for token in the `~/.aws/sso/cache` directory.
    var bearerTokenIdentityResolver: any BearerTokenIdentityResolver { get set }

    /// Add an `HttpInterceptorProvider` that will be used to provide interceptors for all HTTP operations.
    ///
    /// - Parameter provider: The `HttpInterceptorProvider` to add.
    func addInterceptorProvider(_ provider: HttpInterceptorProvider)
}

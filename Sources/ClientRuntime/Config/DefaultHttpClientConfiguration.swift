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

    /// The HTTP client to use, configured with the supplied configuration.
    ///
    /// By default, Swift SDK will set this to `CRTClientEngine` client on Linux platforms,
    /// and `URLSessionHttpClient` on Apple platforms.
    var httpClientEngine: HTTPClient { get set }

    /// Configuration for the HTTP client.
    var httpClientConfiguration: HttpClientConfiguration { get set }

    /// List of auth schemes to use for requests.
    ///
    /// Defaults to auth schemes defined on the underlying Smithy model of a service.
    var authSchemes: [AuthScheme]? { get set }

    /// The auth scheme resolver to use for resolving the auth scheme.
    ///
    /// Defaults to an auth scheme resolver generated based on the underlying Smithy model of a service.
    var authSchemeResolver: AuthSchemeResolver { get set }

    /// The token identity resolver to use for bearer token authentication.
    ///
    /// Default resolver will look for the token in the `~/.aws/sso/cache` directory.
    var bearerTokenIdentityResolver: any BearerTokenIdentityResolver { get set }

    /// Adds a `HttpInterceptorProvider` that will be used to provide interceptors for all HTTP operations.
    ///
    /// - Parameter provider: The `HttpInterceptorProvider` to add.
    mutating func addInterceptorProvider(_ provider: HttpInterceptorProvider)
}

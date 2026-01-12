//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyHTTPAPI.HTTPClient
import protocol SmithyHTTPAuthAPI.AuthScheme
import protocol SmithyHTTPAuthAPI.AuthSchemeResolver
import protocol SmithyIdentity.AWSCredentialIdentityResolver
import protocol SmithyIdentity.BearerTokenIdentityResolver

public protocol DefaultHttpClientConfiguration: ClientConfiguration {

    /// The HTTP client to use, configured with the supplied configuration.
    ///
    /// By default, Swift SDK will set this to `CRTClientEngine` client on Linux platforms,
    /// and `URLSessionHttpClient` on Apple platforms.
    var httpClientEngine: HTTPClient { get set }

    /// Configuration for the HTTP client.
    var httpClientConfiguration: HttpClientConfiguration { get set }

    var partitionID: String? { get }

    /// List of auth schemes to use for requests.
    ///
    /// Defaults to auth schemes defined on the underlying Smithy model of a service.
    var authSchemes: [AuthScheme]? { get set }

    /// An ordered, prioritized list of auth scheme IDs that should be used for this client's requests.
    ///
    /// If no auth scheme preference is given, the first supported auth scheme defined in `authSchemes`
    /// will be used.  If a value was not provided for `authSchemes`, then the service's first defined, supported auth scheme will be used.
    var authSchemePreference: [String]? { get set }

    /// The auth scheme resolver to use for resolving the auth scheme.
    ///
    /// Defaults to an auth scheme resolver generated based on the underlying Smithy model of a service.
    var authSchemeResolver: AuthSchemeResolver { get set }

    /// The token identity resolver to use for bearer token authentication.
    ///
    /// Default resolver will look for the token in the `~/.aws/sso/cache` directory.
    var bearerTokenIdentityResolver: any BearerTokenIdentityResolver { get set }

    /// The AWS credential identity resolver to be used for AWS credentials.
    var awsCredentialIdentityResolver: any AWSCredentialIdentityResolver { get set }

    /// Adds a `HttpInterceptorProvider` that will be used to provide interceptors for all HTTP operations.
    ///
    /// - Parameter provider: The `HttpInterceptorProvider` to add.
    mutating func addInterceptorProvider(_ provider: HttpInterceptorProvider)
}

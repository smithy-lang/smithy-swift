//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyHTTPAPI.HTTPClient
import struct SmithyRetries.DefaultRetryStrategy

public class DefaultHttpClientPlugin: Plugin {

    var httpClientConfiguration: HttpClientConfiguration

    var httpClient: HTTPClient

    public init(httpClient: HTTPClient, httpClientConfiguration: HttpClientConfiguration) {
        self.httpClient = httpClient
        self.httpClientConfiguration = httpClientConfiguration
    }

    public convenience init(httpClientConfiguration: HttpClientConfiguration) {
        self.init(
            httpClient: DefaultSDKRuntimeConfiguration<DefaultRetryStrategy, DefaultRetryErrorInfoProvider>
                .makeClient(httpClientConfiguration: httpClientConfiguration),
            httpClientConfiguration: httpClientConfiguration
        )
    }

    public func configureClient(clientConfiguration: ClientConfiguration) async throws -> ClientConfiguration {
        // Since configurations are now immutable structs, we can't mutate them.
        // The HTTP client configuration and engine are already set in the configuration's initializer,
        // so this plugin doesn't need to do anything.
        return clientConfiguration
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

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

    public func configureClient(clientConfiguration: ClientConfiguration) {
        if var config = clientConfiguration as? DefaultHttpClientConfiguration {
            config.httpClientConfiguration = self.httpClientConfiguration
            config.httpClientEngine = self.httpClient
        }
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AsyncHTTPClient
import NIOCore
import SmithyHTTPClientAPI

extension HTTPClient.Configuration {

    static func from(
        httpClientConfiguration: SmithyHTTPClientAPI.HTTPClientConfiguration
    ) -> HTTPClient.Configuration {
        let connect: TimeAmount? = httpClientConfiguration.connectTimeout != nil
            ? .seconds(Int64(httpClientConfiguration.connectTimeout!))
            : nil

        let read: TimeAmount? = .seconds(Int64(httpClientConfiguration.socketTimeout))

        let timeout = HTTPClient.Configuration.Timeout(
            connect: connect,
            read: read
        )

        let pool = HTTPClient.Configuration.ConnectionPool(
            idleTimeout: .seconds(60), // default
            concurrentHTTP1ConnectionsPerHostSoftLimit:
                httpClientConfiguration.maxConnections
        )

        return .init(
            tlsConfiguration: nil, // TODO
            redirectConfiguration: nil,
            timeout: timeout,
            connectionPool: pool,
            proxy: nil,
            ignoreUncleanSSLShutdown: false,
            decompression: .disabled
        )
    }
}

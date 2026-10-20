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

        let proxy: HTTPClient.Configuration.Proxy? = httpClientConfiguration.proxy.map { p in
            if let user = p.username, let pass = p.password {
                return .server(
                    host: p.host,
                    port: p.port,
                    authorization: .basic(credentials: "\(user):\(pass)")
                )
            }
            return .server(host: p.host, port: p.port)
        }

        return .init(
            tlsConfiguration: nil, // TODO
            redirectConfiguration: nil,
            timeout: timeout,
            connectionPool: pool,
            proxy: proxy,
            ignoreUncleanSSLShutdown: false,
            decompression: .disabled
        )
    }
}

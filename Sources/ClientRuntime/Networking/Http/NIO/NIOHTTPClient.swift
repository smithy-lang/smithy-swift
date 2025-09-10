//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AsyncHTTPClient
import SmithyHTTPAPI
import NIOCore
import NIOPosix

/// AsyncHTTPClient-based HTTP client implementation that conforms to SmithyHTTPAPI.HTTPClient
/// This implementation is thread-safe and supports concurrent request execution.
public final class NIOHTTPClient: SmithyHTTPAPI.HTTPClient {
    private let client: AsyncHTTPClient.HTTPClient
    private let config: HttpClientConfiguration

    /// Creates a new `NIOHTTPClient`.
    ///
    /// The client is created with its own internal `AsyncHTTPClient`, which is configured with system defaults.
    /// - Parameters:
    ///   - httpClientConfiguration: The configuration to use for the client's `AsyncHTTPClient` setup.
    public init(
        httpClientConfiguration: HttpClientConfiguration,
    ) throws {
        self.config = httpClientConfiguration
        self.client = AsyncHTTPClient.HTTPClient(
            configuration: .init() // TODO
        )
    }

    public func send(request: SmithyHTTPAPI.HTTPRequest) async throws -> SmithyHTTPAPI.HTTPResponse {
        // TODO
        return HTTPResponse()
    }
}

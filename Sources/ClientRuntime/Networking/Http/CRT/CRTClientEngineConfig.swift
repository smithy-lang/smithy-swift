/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

struct CRTClientEngineConfig {

    /// Max connections the manager can contain per endpoint
    let maxConnectionsPerEndpoint: Int

    /// The IO channel window size to use for connections in the connection pool
    let windowSize: Int

    /// The default is true for clients and false for servers.
    /// You should not change this default for clients unless
    /// you're testing and don't want to fool around with CA trust stores.
    /// If you set this in server mode, it enforces client authentication.
    let verifyPeer: Bool

    /// Timeout in MS for connections
    let connectTimeoutMs: UInt32?

    public init(
        maxConnectionsPerEndpoint: Int = 50,
        windowSize: Int = 16 * 1024 * 1024,
        verifyPeer: Bool = true,
        connectTimeoutMs: UInt32? = nil
    ) {
        self.maxConnectionsPerEndpoint = maxConnectionsPerEndpoint
        self.windowSize = windowSize
        self.verifyPeer = verifyPeer
        self.connectTimeoutMs = connectTimeoutMs
    }
}

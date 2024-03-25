/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import AwsCommonRuntimeKit

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

    /// Timeout in MS for connections.
    let connectTimeoutMs: UInt32?

<<<<<<< HEAD
    /// Context for configuring TLS Options
=======
    /// Context for configuring TLS options
>>>>>>> 2390550f (add comment and comma)
    let tlsContext: TLSContext?

    /// Timeout in seconds for sockets.
    let socketTimeout: UInt32?

    public init(
        maxConnectionsPerEndpoint: Int = 50,
        windowSize: Int = 16 * 1024 * 1024,
        verifyPeer: Bool = true,
        connectTimeoutMs: UInt32? = nil,
<<<<<<< HEAD
        tlsContext: TLSContext? = nil
        socketTimeout: UInt32? = nil
=======
        tlsContext: TLSContext? = nil,
>>>>>>> 2390550f (add comment and comma)
    ) {
        self.maxConnectionsPerEndpoint = maxConnectionsPerEndpoint
        self.windowSize = windowSize
        self.verifyPeer = verifyPeer
        self.connectTimeoutMs = connectTimeoutMs
        self.tlsContext = tlsContext
        self.socketTimeout = socketTimeout
    }
}

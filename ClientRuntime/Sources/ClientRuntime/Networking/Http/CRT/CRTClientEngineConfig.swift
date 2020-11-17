//
// Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.

import Foundation

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
    
    public init(maxConnectionsPerEndpoint: Int = 50,
                windowSize: Int = 16 * 1024 * 1024,
                verifyPeer: Bool = true) {
        self.maxConnectionsPerEndpoint = maxConnectionsPerEndpoint
        self.windowSize = windowSize
        self.verifyPeer = verifyPeer
    }
}

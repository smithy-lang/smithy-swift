//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol Smithy.LogAgent

/// A Logger Provider provides implementations of LogAgents.
public protocol LoggerProvider: Sendable {
    /// Provides a LogAgent.
    ///
    /// - Parameter name: the name associated with the LogAgent
    /// - Returns: a LogAgent
    func getLogger(name: String) -> LogAgent
}

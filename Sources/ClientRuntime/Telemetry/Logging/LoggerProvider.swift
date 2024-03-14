//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A Logger Provider provides implementations of LogAgents.
public protocol LoggerProvider {
    /// Provides a LogAgent.
    ///
    /// - Parameter name: the name associated with the LogAgent
    /// - Returns: a LogAgent
    func getLogger(name: String) -> LogAgent
}

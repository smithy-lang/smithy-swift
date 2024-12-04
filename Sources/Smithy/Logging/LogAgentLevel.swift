//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Logging

public enum LogAgentLevel: String, Codable, CaseIterable {
    case trace
    case debug
    case info
    case notice
    case warn
    case error
    case fatal

    func toLoggerLevel() -> Logger.Level {
        switch self {
        case .trace:
            return .trace
        case .debug:
            return .debug
        case .info:
            return .info
        case .notice:
            return .notice
        case .warn:
            return .warning
        case .error:
            return .error
        case .fatal:
            return .critical
        }
    }
}

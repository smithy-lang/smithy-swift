//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Logging

/// Wrapper for Logger.Level; used by SDKLoggingSystem.
public enum SDKLogLevel: String, Codable, CaseIterable, Sendable {
    case trace
    case debug
    case info
    case notice
    case warning
    case error
    case critical

    public func toLoggerType() -> Logger.Level {
        switch self {
        case .trace:
            return .trace
        case .debug:
            return .debug
        case .info:
            return .info
        case .notice:
            return .notice
        case .warning:
            return .warning
        case .error:
            return .error
        case .critical:
            return .critical
        }
    }
}

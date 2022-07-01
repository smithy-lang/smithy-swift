/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Logging

public struct SwiftLogger: LogAgent {
    private var logger: Logger
    private let label: String

    public init(label: String) {
        self.label = label
        self.logger = Logger(label: label)
    }

    public var level: LogAgentLevel {
        get {
            return self.logger.logLevel.toLogAgentLevel()
        }
        set(value) {
            self.logger.logLevel = value.toLoggerLevel()
        }
    }

    public var name: String {
        return label
    }
    
    public func log(level: LogAgentLevel,
                    message: String,
                    metadata: [String: String]?,
                    source: String,
                    file: String,
                    function: String,
                    line: UInt) {
        let mappedDict = metadata?.mapValues { (value) -> Logger.MetadataValue in
            return Logger.MetadataValue.string(value)
        }
        self.logger.log(level: level.toLoggerLevel(),
                        Logger.Message(stringLiteral: message),
                        metadata: mappedDict,
                        source: source,
                        file: file,
                        function: function,
                        line: line)
    }
}

extension Logger.Level {
    func toLogAgentLevel() -> LogAgentLevel {
        switch self {
        case .trace:
            return .trace
        case .debug:
            return .debug
        case .info, .notice:
            return .info
        case .warning:
            return .warn
        case .error:
            return .error
        case .critical:
            return .fatal
        }
    }
}

extension LogAgentLevel {
    func toLoggerLevel() -> Logger.Level {
        switch self {
        case .trace:
            return .trace
        case .debug:
            return .debug
        case .info:
            return .info
        case .warn:
            return .warning
        case .error:
            return .error
        case .fatal:
            return .critical
        }
    }
}

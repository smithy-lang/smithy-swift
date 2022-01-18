/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Logging

public struct SwiftLogger: LogAgent {
    private let logger: Logger
    private let label: String
    private var logLevel: LogAgentLevel

    public init(label: String) {
        self.label = label
        self.logger = Logger(label: label)
        self.logLevel = LogAgentLevel.info
    }

    public var level: LogAgentLevel {
        get {
            return logLevel
        }
        set(value) {
            logLevel = value
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
        self.logger.log(level: logLevel.toLoggerLevel(),
                        Logger.Message(stringLiteral: message),
                        metadata: mappedDict,
                        source: source,
                        file: file,
                        function: function,
                        line: line)
    }
}

extension LogAgentLevel {
    func toLoggerLevel() -> Logger.Level {
        switch(self) {
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

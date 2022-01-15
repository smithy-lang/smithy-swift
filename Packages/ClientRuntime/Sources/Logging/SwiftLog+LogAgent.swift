/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Logging
import enum AwsCommonRuntimeKit.LogLevel

public struct SwiftLogger: LogAgent {
    private let logger: Logger
    private let label: String
    private var logLevel: Logger.Level

    public init(label: String) {
        self.label = label
        self.logger = Logger(label: label)
        self.logLevel = Logger.Level.info
    }

    public var level: AwsCommonRuntimeKit.LogLevel {
        get {
            return AwsCommonRuntimeKit.LogLevel.fromString(string: logLevel.rawValue)
        }
        set(value) {
            logLevel = Logger.Level.init(rawValue: value.stringValue) ?? Logger.Level.info
        }
    }

    public var name: String {
        return label
    }
    
    public func log(level: LogLevel,
             message: String,
             metadata: [String: String]?,
             source: String,
             file: String,
             function: String,
             line: UInt) {
        let mappedDict = metadata?.mapValues { (value) -> Logger.MetadataValue in
            return Logger.MetadataValue.string(value)
        }
        self.logger.log(level: Logger.Level.init(rawValue: level.stringValue) ?? Logger.Level.info,
                        Logger.Message(stringLiteral: message),
                        metadata: mappedDict,
                        source: source)
    }
    
    func info(_ message: String) {
        self.logger.info(Logger.Message(stringLiteral: message))
    }
    
    func debug(_ message: String) {
        self.logger.debug(Logger.Message(stringLiteral: message))
    }
    
    func warn(_ message: String) {
        self.logger.warning(Logger.Message(stringLiteral: message))
    }
    
    func error(_ message: String) {
        self.logger.error(Logger.Message(stringLiteral: message))
    }
    
    func trace(_ message: String) {
        self.logger.trace(Logger.Message(stringLiteral: message))
    }
    
    func fatal(_ message: String) {
        self.logger.critical(Logger.Message(stringLiteral: message))
    }
}

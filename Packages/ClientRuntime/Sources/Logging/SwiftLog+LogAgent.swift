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
                        source: source,
                        file: file,
                        function: function,
                        line: line)
    }
}

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Logging
import enum AwsCommonRuntimeKit.LogLevel

extension Logger: LogAgent {
    
    var level: LogLevel {
        get {
            return LogLevel.fromString(string: logLevel.rawValue)
        }
        set(value) {
            logLevel = Level.init(rawValue: value.stringValue) ?? Level.info
        }
    }
    
    var name: String {
            return label
    }
    
    func log(level: LogLevel,
             message: String,
             metadata: [String: String]?,
             source: String,
             file: String,
             function: String,
             line: UInt) {
        let mappedDict = metadata?.mapValues { (value) -> MetadataValue in
            return MetadataValue.string(value)
        }
        self.log(level: Level.init(rawValue: level.stringValue) ?? Level.info,
                 Message(stringLiteral: message),
                 metadata: mappedDict,
                 source: source)
    }
    
    func info(_ message: String) {
        info(Message(stringLiteral: message))
    }
    
    func debug(_ message: String) {
        debug(Message(stringLiteral: message))
    }
    
    func warn(_ message: String) {
        warning(Message(stringLiteral: message))
    }
    
    func error(_ message: String) {
        error(Message(stringLiteral: message))
    }
    
    func trace(_ message: String) {
        trace(Message(stringLiteral: message))
    }
    
    func fatal(_ message: String) {
        critical(Message(stringLiteral: message))
    }
}

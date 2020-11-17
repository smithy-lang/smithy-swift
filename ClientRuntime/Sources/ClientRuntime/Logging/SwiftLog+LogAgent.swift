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
//

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
    
    func log(level: LogLevel,
             message: String,
             metadata: [String: String],
             source: String,
             file: String = #file,
             function: String = #function,
             line: UInt = #line) {
        let mappedDict = metadata.mapValues { (value) -> MetadataValue in
            return MetadataValue.string(value)
        }
        self.log(level: Level.init(rawValue: level.stringValue) ?? Level.info,
                 Message(stringLiteral: message),
                 metadata: mappedDict,
                 source: source)
    }
    
    var name: String {
            return label
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

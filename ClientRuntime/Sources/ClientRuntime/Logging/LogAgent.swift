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

import AwsCommonRuntimeKit

protocol LogAgent {
    ///name of the struct or class where the logger was instantiated from
    var name: String {get}
    
    /// Get or set the configured log level.
    var level: LogLevel {get set}
    
    /// This method is called when a `LogAgent` must emit a log message.
    ///
    /// - parameters:
    ///     - level: The `LogLevel` the message was logged at.
    ///     - message: The message to log.
    ///     - metadata: The metadata associated to this log message as a dictionary
    ///     - source: The source where the log message originated, for example the logging module.
    ///     - file: The file the log message was emitted from.
    ///     - function: The function the log line was emitted from.
    ///     - line: The line the log message was emitted from.
    func log(level: LogLevel,
             message: String,
             metadata: [String: String]?,
             source: String,
             file: String,
             function: String,
             line: UInt)
}

extension LogAgent {
    
    internal static func currentModule(filePath: String = #file) -> String {
        let utf8All = filePath.utf8
        return filePath.utf8.lastIndex(of: UInt8(ascii: "/")).flatMap { lastSlash -> Substring? in
            utf8All[..<lastSlash].lastIndex(of: UInt8(ascii: "/")).map { secondLastSlash -> Substring in
                filePath[utf8All.index(after: secondLastSlash) ..< lastSlash]
            }
        }.map {
            String($0)
        } ?? "n/a"
    }
    
    /// Log a message passing with the `LogLevel.trace` log level.
    func info(_ message: String) {
        self.log(level: LogLevel.info,
                 message: message,
                 metadata: nil,
                 source: Self.currentModule(),
                 file: #file,
                 function: #function,
                 line: #line)
    }
    
    /// Log a message passing with the `LogLevel.warn` log level.
    func warn(_ message: String) {
        self.log(level: LogLevel.warn,
                 message: message,
                 metadata: nil,
                 source: Self.currentModule(),
                 file: #file,
                 function: #function,
                 line: #line)
    }
    
    /// Log a message passing with the `LogLevel.debug` log level.
    func debug(_ message: String) {
        self.log(level: LogLevel.debug,
                 message: message,
                 metadata: nil,
                 source: Self.currentModule(),
                 file: #file,
                 function: #function,
                 line: #line)
    }
    
    /// Log a message passing with the `LogLevel.error` log level.
    func error(_ message: String) {
        self.log(level: LogLevel.error,
                 message: message,
                 metadata: nil,
                 source: Self.currentModule(),
                 file: #file,
                 function: #function,
                 line: #line)
    }
    
    /// Log a message passing with the `LogLevel.trace` log level.
    func trace(_ message: String) {
        self.log(level: LogLevel.trace,
                 message: message,
                 metadata: nil,
                 source: Self.currentModule(),
                 file: #file,
                 function: #function,
                 line: #line)
    }
    
    /// Log a message passing with the `LogLevel.fatal` log level.
    func fatal(_ message: String) {
        self.log(level: LogLevel.fatal,
                 message: message,
                 metadata: nil,
                 source: Self.currentModule(),
                 file: #file,
                 function: #function,
                 line: #line)
    }
}

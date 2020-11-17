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
             metadata: [String: String],
             source: String,
             file: String,
             function: String,
             line: UInt)
    
    /// Log a message passing with the `LogLevel.trace` log level.
    func info(_ message: String)
    
    /// Log a message passing with the `LogLevel.warn` log level.
    func warn(_ message: String)
    
    /// Log a message passing with the `LogLevel.debug` log level.
    func debug(_ message: String)
    
    /// Log a message passing with the `LogLevel.error` log level.
    func error(_ message: String)
    
    /// Log a message passing with the `LogLevel.trace` log level.
    func trace(_ message: String)
    
    /// Log a message passing with the `LogLevel.fatal` log level.
    func fatal(_ message: String)
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol LogAgent {
    /// name of the struct or class where the logger was instantiated from
    var name: String { get }

    /// Get or set the configured log level.
    var level: LogAgentLevel { get set }

    /// This method is called when a `LogAgent` must emit a log message.
    ///
    /// - parameters:
    ///     - level: The `LogAgentLevel` the message was logged at.
    ///     - message: The message to log.
    ///     - metadata: The metadata associated to this log message as a dictionary
    ///     - source: The source where the log message originated, for example the logging module.
    ///     - file: The file the log message was emitted from.
    ///     - function: The function the log line was emitted from.
    ///     - line: The line the log message was emitted from.
    func log(level: LogAgentLevel,
             message: String,
             metadata: [String: String]?,
             source: String,
             file: String,
             function: String,
             line: UInt)
}

public enum LogAgentLevel: String, Codable, CaseIterable {
    case trace
    case debug
    case info
    case warn
    case error
    case fatal
}

public extension LogAgent {

    /// Log a message passing with the `.info` log level.
    func info(_ message: String, file: String = #fileID, function: String = #function, line: UInt = #line) {
        self.log(level: .info,
                 message: message,
                 metadata: nil,
                 source: currentModule(fileID: file),
                 file: file,
                 function: function,
                 line: line)
    }

    /// Log a message passing with the `LogLevel.warn` log level.
    func warn(_ message: String, file: String = #fileID, function: String = #function, line: UInt = #line) {
        self.log(level: .warn,
                 message: message,
                 metadata: nil,
                 source: currentModule(fileID: file),
                 file: file,
                 function: function,
                 line: line)
    }

    /// Log a message passing with the `.debug` log level.
    func debug(_ message: String, file: String = #fileID, function: String = #function, line: UInt = #line) {
        self.log(level: .debug,
                 message: message,
                 metadata: nil,
                 source: currentModule(fileID: file),
                 file: file,
                 function: function,
                 line: line)
    }

    /// Log a message passing with the `.error` log level.
    func error(_ message: String, file: String = #fileID, function: String = #function, line: UInt = #line) {
        self.log(level: .error,
                 message: message,
                 metadata: nil,
                 source: currentModule(fileID: file),
                 file: file,
                 function: function,
                 line: line)
    }

    /// Log a message passing with the `.trace` log level.
    func trace(_ message: String, file: String = #fileID, function: String = #function, line: UInt = #line) {
        self.log(level: .trace,
                 message: message,
                 metadata: nil,
                 source: currentModule(fileID: file),
                 file: file,
                 function: function,
                 line: line)
    }

    /// Log a message passing with the `.fatal` log level.
    func fatal(_ message: String, file: String = #fileID, function: String = #function, line: UInt = #line) {
        self.log(level: .fatal,
                 message: message,
                 metadata: nil,
                 source: currentModule(fileID: file),
                 file: file,
                 function: function,
                 line: line)
    }
}

/// Parses the module name from `#fileID`.
///
/// Instructions for parsing module from `#fileID` are here:
/// https://developer.apple.com/documentation/swift/fileid()
/// - Parameter fileID: The value of the `#fileID` macro at the point of logging.
/// - Returns: The name of the module, as parsed from the passed `#fileID`.
private func currentModule(fileID: String) -> String {
    let utf8All = fileID.utf8
    if let slashIndex = utf8All.firstIndex(of: UInt8(ascii: "/")) {
        return String(fileID[..<slashIndex])
    } else {
        return "n/a"
    }
}

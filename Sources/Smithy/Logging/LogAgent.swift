//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Logging

public protocol LogAgent {
    /// name of the struct or class where the logger was instantiated from
    var label: String { get }

    /// This method is called when a `LogAgent` must emit a log message.
    ///
    /// - parameters:
    ///     - level: The `Logger.Level` the message was logged at.
    ///     - message: The message to log.
    ///     - metadata: The metadata associated to this log message as a dictionary
    ///     - source: The source where the log message originated, for example the logging module.
    ///     - file: The file the log message was emitted from.
    ///     - function: The function the log line was emitted from.
    ///     - line: The line the log message was emitted from.
    func log(level: Logger.Level,
             message: @autoclosure () -> String,
             metadata: @autoclosure () -> [String: String]?,
             source: @autoclosure () -> String,
             file: String,
             function: String,
             line: UInt)
}

public extension LogAgent {
    /// Use for messages that are typically seen during tracing.
    func trace(
        _ message: @autoclosure() -> String,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        self.log(level: .trace,
                 message: message(),
                 metadata: nil,
                 source: currentModule(fileID: file),
                 file: file,
                 function: function,
                 line: line)
    }

    /// Use for messages that are typically seen during debugging.
    func debug(
        _ message: @autoclosure() -> String,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        self.log(level: .debug,
                 message: message(),
                 metadata: nil,
                 source: currentModule(fileID: file),
                 file: file,
                 function: function,
                 line: line)
    }

    /// Use for informational messages.
    func info(
        _ message: @autoclosure() -> String,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        self.log(level: .info,
                 message: message(),
                 metadata: nil,
                 source: currentModule(fileID: file),
                 file: file,
                 function: function,
                 line: line)
    }

    /// Use for non-error messages that may need special attention.
    func notice(
        _ message: @autoclosure() -> String,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        self.log(level: .notice,
                 message: message(),
                 metadata: nil,
                 source: currentModule(fileID: file),
                 file: file,
                 function: function,
                 line: line)
    }

    /// Use for non-error messages that are more severe than `.notice`.
    func warning(
        _ message: @autoclosure() -> String,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        self.log(level: .warning,
                 message: message(),
                 metadata: nil,
                 source: currentModule(fileID: file),
                 file: file,
                 function: function,
                 line: line)
    }

    /// Use for errors.
    func error(
        _ message: @autoclosure() -> String,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        self.log(level: .error,
                 message: message(),
                 metadata: nil,
                 source: currentModule(fileID: file),
                 file: file,
                 function: function,
                 line: line)
    }

    /// Appropriate for critical error conditions that usually require immediate
    /// attention.
    func critical(
        _ message: @autoclosure() -> String,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        self.log(level: .critical,
                 message: message(),
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

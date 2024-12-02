//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import Smithy
import ClientRuntime
import Logging

final class SwiftLoggerTests: XCTestCase {

    func test_log_logsTraceLevelMessage() throws {
        try logsLeveledMessage(logLevel: .trace, loggerBlock: { $0.trace })
    }

    func test_log_logsDebugLevelMessage() throws {
        try logsLeveledMessage(logLevel: .debug, loggerBlock: { $0.debug })
    }

    func test_log_logsInfoLevelMessage() throws {
        try logsLeveledMessage(logLevel: .info, loggerBlock: { $0.info })
    }

    func test_log_logsWarnLevelMessage() throws {
        try logsLeveledMessage(logLevel: .warning, loggerBlock: { $0.warn })
    }

    func test_log_logsErrorLevelMessage() throws {
        try logsLeveledMessage(logLevel: .error, loggerBlock: { $0.error })
    }

    func test_log_logsFatalLevelMessage() throws {
        try logsLeveledMessage(logLevel: .critical, loggerBlock: { $0.fatal })
    }

    private func logsLeveledMessage(
        logLevel: Logger.Level,
        loggerBlock: (SwiftLogger) -> (String, String, String, UInt) -> Void,
        testFile: StaticString = #filePath,
        testLine: UInt = #line
    ) throws {
        // Select randomized params for the test
        let logMessage = UUID().uuidString
        let module = UUID().uuidString
        let fileName = UUID().uuidString
        let fileID = "\(module)/\(fileName).swift"
        let function = UUID().uuidString
        let line = UInt.random(in: 0...UInt.max)

        // Create a TestLogHandler, then create a SwiftLogger (the test subject)
        // with it.
        var logHandler: TestLogHandler!
        let subject = SwiftLogger(label: "Test", logLevel: .trace, factory: { label in
            logHandler = TestLogHandler(label: label)
            return logHandler
        })

        // Invoke the logger, then get the TestLogInvocation with the params sent into
        // swift-log.
        loggerBlock(subject)(logMessage, fileID, function, line)
        let invocation = try XCTUnwrap(logHandler.invocations.first)

        // Verify the assertions on each param submitted into swift-log.
        XCTAssertEqual(invocation.level, logLevel, file: testFile, line: testLine)
        XCTAssertEqual(invocation.message, Logger.Message(stringLiteral: logMessage), file: testFile, line: testLine)
        XCTAssertEqual(invocation.source, module, file: testFile, line: testLine)
        XCTAssertEqual(invocation.file, fileID, file: testFile, line: testLine)
        XCTAssertEqual(invocation.function, function, file: testFile, line: testLine)
        XCTAssertEqual(invocation.line, line, file: testFile, line: testLine)
    }
}


private class TestLogHandler: LogHandler {
    let label: String
    var invocations = [TestLogInvocation]()

    init(label: String) {
        self.label = label
    }

    subscript(metadataKey metadataKey: String) -> Logging.Logger.Metadata.Value? {
        get {
            metadata[metadataKey]
        }
        set {
            if let newValue {
                metadata.updateValue(newValue, forKey: metadataKey)
            } else {
                metadata.removeValue(forKey: metadataKey)
            }
        }
    }
    
    var metadata: Logging.Logger.Metadata = Logging.Logger.Metadata()

    var logLevel: Logging.Logger.Level = .trace

    func log(
        level: Logger.Level,
        message: Logger.Message,
        metadata: Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        invocations.append(
            TestLogInvocation(
                level: level,
                message: message,
                metadata: metadata,
                source: source,
                file: file,
                function: function,
                line: line
            )
        )
    }
}

private struct TestLogInvocation {
    let level: Logger.Level
    let message: Logger.Message
    let metadata: Logger.Metadata?
    let source: String
    let file: String
    let function: String
    let line: UInt
}

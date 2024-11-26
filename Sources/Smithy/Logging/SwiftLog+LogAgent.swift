//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Logging

public struct SwiftLogger: LogAgent {
    private let logger: Logger
    public let label: String

    public init(label: String) {
        self.label = label
        self.logger = Logger(label: label)
    }

    // This initializer is currently only used in tests, to inject a mock LogHandler.
    init(label: String, factory: (String) -> any LogHandler) {
        self.label = label
        self.logger = Logger(label: label, factory: factory)
    }

    public func log(
        level: Logger.Level,
        message: @autoclosure () -> String,
        metadata: @autoclosure () -> [String: String]?,
        source: @autoclosure () -> String,
        file: String,
        function: String,
        line: UInt
    ) {
        self.logger.log(
            level: level,
            Logger.Message(stringLiteral: message()),
            metadata: metadata()?.mapValues { Logger.MetadataValue.string($0) },
            source: source(),
            file: file as String,
            function: function as String,
            line: line
        )
    }
}

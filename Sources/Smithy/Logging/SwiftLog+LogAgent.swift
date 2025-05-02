//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Logging

public struct SwiftLogger: LogAgent {
    private let logger: Logger
    private let label: String

    public init(label: String) {
        self.label = label
        self.logger = Logger(label: label)
    }

    @available(*, deprecated, message: "This API is deprecated. Use init(label:) instead.")
    public init(label: String, logLevel: LogAgentLevel) {
        self.init(label: label)
    }

    // This initializer is currently only used in tests, to inject a mock LogHandler.
    init(label: String, factory: (String) -> any LogHandler) {
        self.label = label
        self.logger = Logger(label: label, factory: factory)
    }

    public var name: String {
        return label
    }

    public func log(
        level: LogAgentLevel,
        message: @autoclosure () -> String,
        metadata: @autoclosure () -> [String: String]?,
        source: @autoclosure () -> String,
        file: String,
        function: String,
        line: UInt
    ) {
        self.logger.log(
            level: level.toLoggerLevel(),
            Logger.Message(stringLiteral: message()),
            metadata: metadata()?.mapValues { Logger.MetadataValue.string($0) },
            source: source(),
            file: file as String,
            function: function as String,
            line: line
        )
    }
}

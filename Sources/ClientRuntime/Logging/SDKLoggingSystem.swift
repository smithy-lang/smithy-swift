//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Logging

public actor SDKLoggingSystem {
    private static var isInitialized = false
    private static var factories: [String: SDKLogHandlerFactory] = [:]

    public static func add(logHandlerFactory: SDKLogHandlerFactory) {
        let label = logHandlerFactory.label
        factories[label] = logHandlerFactory
    }

    public static func initialize(defaultLogLevel: SDKLogLevel = .info) {
        if isInitialized { return } else { isInitialized = true }
        LoggingSystem.bootstrap { label in
            if let factory = factories[label] {
                return factory.construct(label: label)
            }
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = defaultLogLevel.toLoggerType()
            return handler
        }
    }

    public static func initialize(logLevel: SDKLogLevel) {
        if isInitialized { return } else { isInitialized = true }
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = logLevel.toLoggerType()
            return handler
        }
    }
}

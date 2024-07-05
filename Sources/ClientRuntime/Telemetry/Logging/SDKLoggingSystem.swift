//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Logging

public actor SDKLoggingSystem {
    private var isInitialized = false
    private var factories: [String: SDKLogHandlerFactory] = [:]

    public func add(logHandlerFactory: SDKLogHandlerFactory) {
        let label = logHandlerFactory.label
        factories[label] = logHandlerFactory
    }

    public func initialize(defaultLogLevel: SDKLogLevel = .info) async {
        if isInitialized { return } else { isInitialized = true }
        LoggingSystem.bootstrap { [self] label in
            if let factory = factories[label] {
                return factory.construct(label: label)
            }
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = defaultLogLevel.toLoggerType()
            return handler
        }
    }

    public func initialize(logLevel: SDKLogLevel) async {
        if isInitialized { return } else { isInitialized = true }
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = logLevel.toLoggerType()
            return handler
        }
    }
}

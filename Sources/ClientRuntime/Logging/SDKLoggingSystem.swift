//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Logging

public class SDKLoggingSystem {
    private static var isInitialized = false
    private static var factories: [String: SDKLogHandlerFactory] = [:]

    public class func add(logHandlerFactory: SDKLogHandlerFactory) {
        let label = logHandlerFactory.label
        factories[label] = logHandlerFactory
    }

    public class func initialize(defaultLogLevel: SDKLogLevel = .info) {
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

    public class func initialize(logLevel: SDKLogLevel) {
        if isInitialized { return } else { isInitialized = true }
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = logLevel.toLoggerType()
            return handler
        }
    }
}

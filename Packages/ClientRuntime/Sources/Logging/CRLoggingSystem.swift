//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
	
import Logging

public class CRLoggingSystem {
    private static var handlerFactories: [String:CRLogHandlerFactory] = [:]

    public class func add(logHandlerFactory: CRLogHandlerFactory) {
        let label = logHandlerFactory.label
        handlerFactories[label] = logHandlerFactory
    }

    public class func initialize() {
        LoggingSystem.bootstrap { label in
            if let factory = handlerFactories[label] {
                return factory.constructLogHandler(label: label)
            }
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = .info
            return handler
        }
    }

    public class func initialize(logLevel: CRLogLevel) {
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = logLevel.toLoggerType()
            return handler
        }
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Logging

/// Use this to turn SDK logging on.
public actor SDKLoggingSystem {
    private var isInitialized = false
    private var logHandlerFactories: [String: SDKLogHandlerFactory] = [:]

    public init() {}

    /// Adds custom log handler factory to `this.logHandlerFactories`.
    ///
    /// The added log handler factory will be dedicated log handler for any logger with identical label.
    public func add(logHandlerFactory: SDKLogHandlerFactory) {
        logHandlerFactories[logHandlerFactory.label] = logHandlerFactory
    }

    /// Initializes the logging handler factory for the SDK.
    /// The default behavior is to log messages at `.error` or more severe levels.
    ///
    /// The handler factory closure first checks if there exists a custom handler factory in `this.logHandlerFactories` with the same label as the label given to logger initializer. If it exists, then that factory gets used to create the log handler.
    ///
    /// If no custom handler factory is found for the given label, the factory closure creates and returns a `StreamLogHandler` with minimum log level set to `logLevel`.
    ///
    /// Loggers output log only if the log level of the message is equal to or more severe than the underlying log handler's log level. E.g., `logger.info(...)` executes only if the underlying log handler's log level is `.info`, `.debug`, or `.trace`. It does not execute if the underlying log handler's minimum log level is any one of the following levels that are more severe than `.info`: `.notice`, `.warning`, `error`, `critical`.
    ///
    /// - parameters:
    ///     - logLevel: The minimum log level to use for the log handler if no custom log handler factory was found. Default is `.error`.
    public func initialize(defaultLogLevel: SDKLogLevel = .error) async {
        if isInitialized { return } else { isInitialized = true }
        let ptr = logHandlerFactories
        LoggingSystem.bootstrap { label in
            if let factory = ptr[label] {
                return factory.construct(label: label)
            }
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = defaultLogLevel.toLoggerType()
            return handler
        }
    }

    public func initialize(logLevel: SDKLogLevel) async {
        await self.initialize(defaultLogLevel: logLevel)
    }
}

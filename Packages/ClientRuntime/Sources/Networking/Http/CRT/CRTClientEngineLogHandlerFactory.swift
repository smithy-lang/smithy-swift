//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
	
import Logging

public struct CRTClientEngineLogHandlerFactory: CRLogHandlerFactory {
    public var label = "CRTClientEngine"
    let logLevel: CRLogLevel

    public func constructLogHandler(label: String) -> LogHandler {
        var handler = StreamLogHandler.standardOutput(label: label)
        handler.logLevel = logLevel.toLoggerType()
        return handler
    }
    
    public init(logLevel: CRLogLevel) {
        self.logLevel = logLevel
    }
}

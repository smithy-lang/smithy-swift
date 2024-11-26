//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Logging

public struct CRTClientEngineLogHandlerFactory: SDKLogHandlerFactory {
    public var label = "CRTClientEngine"
    let logLevel: Logger.Level

    public func construct(label: String) -> LogHandler {
        var handler = StreamLogHandler.standardOutput(label: label)
        handler.logLevel = logLevel
        return handler
    }

    public init(logLevel: Logger.Level) {
        self.logLevel = logLevel
    }
}

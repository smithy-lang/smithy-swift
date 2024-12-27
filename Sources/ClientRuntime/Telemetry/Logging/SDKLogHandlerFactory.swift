//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Logging

/// Implement this protocol and add an instance of the implementation to `SDKLoggingSystem` to use custom log handlers.
public protocol SDKLogHandlerFactory {
    var label: String { get }
    func construct(label: String) -> LogHandler
}

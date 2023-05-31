//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public enum ErrorFault {
    case client
    case server
}

public protocol ModeledError: Error {
    static var typeName: String { get }
    static var fault: ErrorFault { get }
    static var isRetryable: Bool { get }
    static var isThrottling: Bool { get }
}

extension ModeledError {

    public var typeName: String? {
        Self.typeName
    }
}

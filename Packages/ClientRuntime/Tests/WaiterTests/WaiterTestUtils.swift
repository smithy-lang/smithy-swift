//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@testable import ClientRuntime

// In tests, waiters are used with String as Input & String as Output
// to makes tests as simple as possible.
// These Equatable conformances make the tests easier to read (and write).

extension WaiterConfig.Acceptor.Match: Equatable where Output: Equatable {

    public static func ==(lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.success(let lhs), .success(let rhs)):
            return lhs == rhs
        case (.failure(let lhs), .failure(let rhs)):
            return lhs == rhs
        case (.retry, .retry):
            return true
        default:
            return false
        }
    }
}

extension WaiterOutcome: Equatable where Output: Equatable {

    public static func ==(lhs: WaiterOutcome, rhs: WaiterOutcome) -> Bool {
        lhs.attempts == rhs.attempts && lhs.result == rhs.result
    }
}

extension Result where Success: Equatable, Failure == Error {

    public static func ==(lhs: Result, rhs: Result) -> Bool {
        switch (lhs, rhs) {
        case (.success(let lhs), .success(let rhs)):
            return lhs == rhs
        case (.failure(let lhs), .failure(let rhs)):
            return lhs.localizedDescription == rhs.localizedDescription
        default:
            return false
        }
    }
}

extension WaiterFailureError: Equatable where Output == String {

    public static func ==(lhs: WaiterFailureError, rhs: WaiterFailureError) -> Bool {
        lhs.attempts == rhs.attempts && lhs.failedOnMatch == rhs.failedOnMatch && lhs.result == rhs.result
    }
}

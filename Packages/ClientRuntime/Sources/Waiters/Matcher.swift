//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension Acceptor {

    /// `Acceptor.Matcher` is a Swift-native equivalent of Smithy matchers:
    /// https://awslabs.github.io/smithy/2.0/additional-specs/waiters.html#matcher-union
    public enum Matcher {
        case output((Output) -> Bool)
        case inputOutput((Input, Output) -> Bool)
        case success(Bool)
        case errorType((Error) -> Bool)

        func isAMatch(input: Input, output: Output?, error: Error?) -> Bool {
            switch self {
            case .output(let testClosure):
                guard let output = output else { return false }
                return testClosure(output)
            case .inputOutput(let testClosure):
                guard let output = output else { return false }
                return testClosure(input, output)
            case .success(let success):
                let hasOutput = output != nil
                return success ? hasOutput : !hasOutput
            case .errorType(let testClosure):
                guard let error = error else { return false }
                return testClosure(error)
            }
        }
    }

    /// `Acceptor.Result` encapsulates the action required by an `Acceptor` that matches the
    /// operation's response.
    public enum Result {
        case success(Output)
        case retry
        case failure(Error)
    }
}

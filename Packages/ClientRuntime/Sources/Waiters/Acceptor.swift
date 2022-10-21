//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension WaiterConfig {
    /// `Acceptor` is a Swift-native equivalent of Smithy acceptors:
    /// https://awslabs.github.io/smithy/2.0/additional-specs/waiters.html#acceptor-structure
    public struct Acceptor {

        public typealias Matcher = (Input, Result<Output, Error>) -> Bool

        /// The possible states of a Smithy waiter during the waiting process.
        public enum State {
            /// The waiter has succeeded if this state is reached, and should conclude waiting.
            case success
            /// The waiter should repeat the operation if this state is reached.
            case retry
            /// The waiter has failed if this state is reached, and should conclude waiting.
            case failure
        }

        /// The state that the `Waiter` enters when this `Acceptor` matches the operation response.
        public let state: State

        /// A closure that determines if this `Acceptor` matches the operation response.
        public let matcher: Matcher

        /// Creates a new `Acceptor` that will cause the waiter to enter `state` when `Matcher` is true.
        public init(state: State, matcher: @escaping Matcher) {
            self.state = state
            self.matcher = matcher
        }

        /// Determines if the `Acceptor` matches for the supplied parameters, and returns a
        /// `Acceptor.Match` value which can be used to conclude the wait or initiate retry.
        func evaluate(input: Input, result: Result<Output, Error>) -> Match? {
            guard matcher(input, result) else { return nil }
            switch (state, result) {
            case (.retry, _):
                return .retry
            case (.success, .success(let output)):
                return .success(.success(output))
            case (.success, .failure(let error)):
                return .success(.failure(error))
            case (.failure, .success(let output)):
                return .failure(.success(output))
            case (.failure, .failure(let error)):
                return .failure(.failure(error))
            }
        }

        /// `Acceptor.Match` encapsulates the action required by an `Acceptor` that matches the
        /// operation's response.
        public enum Match {
            case success(Result<Output, Error>)
            case retry
            case failure(Result<Output, Error>)
        }
    }
}

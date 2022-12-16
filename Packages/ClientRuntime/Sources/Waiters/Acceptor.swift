//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension WaiterConfiguration {
    /// `Acceptor` is a Swift-native equivalent of Smithy acceptors:
    /// https://awslabs.github.io/smithy/2.0/additional-specs/waiters.html#acceptor-structure
    /// An `Acceptor` defines a condition (its `matcher`) that will cause the wait operation to transition to
    /// a given state (its `state`).
    public struct Acceptor {

        public typealias Matcher = (Input, Result<Output, Error>) -> Bool

        /// The possible states of a Smithy waiter during the waiting process.
        public enum State {
            /// The waiter has succeeded if this state is reached, and should conclude waiting.
            case success
            /// The waiter should repeat the operation after a delay if this state is reached.
            case retry
            /// The waiter has failed if this state is reached, and should conclude waiting.
            case failure
        }

        /// Used as the root value of an `inputOutput` acceptor, which has the `input` and `output` fields
        /// as its two top level properties.
        ///
        /// Even though `input` and `output` are both guaranteed to be present when this type is created,
        /// these properties are optional because `InputOutput` is handled like any other Smithy model object,
        /// and smithy-swift currently does not support `@required` properties on Smithy models.
        ///
        /// In the future, if smithy-swift is updated to support `@required` properties, these may be made
        /// non-optional and the corresponding Smithy model's members for `input` and `output` should be
        /// marked with `@required` as well.
        public struct InputOutput {
            public let input: Input?
            public let output: Output?

            public init(input: Input, output: Output) {
                self.input = input
                self.output = output
            }
        }

        /// The state that the `Waiter` enters when this `Acceptor` matches the operation response.
        public let state: State

        /// A closure that determines if this `Acceptor` matches the operation response.
        public let matcher: Matcher

        /// Creates a new `Acceptor` that will cause the waiter to enter `state` when `Matcher` is true.
        public init(
            state: State,
            matcher: @escaping Matcher
        ) {
            self.state = state
            self.matcher = matcher
        }

        /// Determines if the `Acceptor` matches for the supplied parameters, and returns a
        /// `Acceptor.Match` value which can be used to conclude the wait or initiate retry.
        func evaluate(
            input: Input,
            result: Result<Output, Error>
        ) -> Match? {
            guard matcher(input, result) else { return nil }
            switch (state, result) {
            case (.retry, _):
                return .retry
            case (.success, let result):
                return .success(result)
            case (.failure, let result):
                return .failure(result)
            }
        }

        /// `Acceptor.Match` encapsulates the action required by an `Acceptor` that matches the
        /// operation's response.
        public enum Match {
            /// An `Acceptor` with `success` state matched an operation, and the associated value
            /// is that operation's result.
            case success(Result<Output, Error>)
            /// An `Acceptor` with `retry` state matched an operation.
            case retry
            /// An `Acceptor` with `failure` state matched an operation, and the associated value
            /// is that operation's result.
            case failure(Result<Output, Error>)
        }
    }
}

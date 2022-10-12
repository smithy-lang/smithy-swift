//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// `Acceptor` is a Swift-native equivalent of Smithy acceptors:
/// https://awslabs.github.io/smithy/2.0/additional-specs/waiters.html#acceptor-structure
public struct Acceptor<Input, Output> {

    public enum State {
        case success
        case retry
        case failure
    }

    public let state: State
    public let matcher: Matcher

    public init(state: State, matcher: Matcher) {
        self.state = state
        self.matcher = matcher
    }
}

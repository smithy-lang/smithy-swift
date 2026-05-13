//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// This type maintains the expectation for which element is expected next
// while JSON parsing.  A stack is maintained because nested object or elements
// each need to keep their own state, so a new ExpectedNext is pushed to the stack
// when an object or array starts, and is popped when it finishes.
enum ExpectedNext {
    case firstElement
    case objectEndOrKey
    case nameSeparator
    case objectValue
    case valueSeparatorOrObjectEnd
    case objectKey
    case arrayEndOrElement
    case arrayElement
    case valueSeparatorOrArrayEnd
    case nothing
}

struct ExpectedNextStack {
    private var storage = [ExpectedNext.firstElement]

    func expectedNext() -> ExpectedNext? {
        return storage.last
    }

    @discardableResult
    mutating func pop() -> ExpectedNext? {
        guard !storage.isEmpty else { return nil }
        return storage.popLast()
    }

    mutating func push(_ state: ExpectedNext) {
        storage.append(state)
    }

    mutating func replace(_ state: ExpectedNext) {
        guard let lastIndex = storage.indices.last else { return }
        storage[lastIndex] = state
    }
}

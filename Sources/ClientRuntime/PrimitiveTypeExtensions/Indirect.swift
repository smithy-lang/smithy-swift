//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@propertyWrapper
public class Indirect<T> {
    public var wrappedValue: T?

    public init(wrappedValue: T? = nil) {
        self.wrappedValue = wrappedValue
    }
}

extension Indirect: Equatable where T: Equatable {

    public static func ==(lhs: Indirect<T>, rhs: Indirect<T>) -> Bool {
        lhs.wrappedValue == rhs.wrappedValue
    }
}

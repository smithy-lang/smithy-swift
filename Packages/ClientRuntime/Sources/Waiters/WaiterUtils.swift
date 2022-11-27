//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension Array {

    func flattenIfPossible<T>(_ transform: (Element) throws -> Array<T>) rethrows -> Array<T> {
        return try flatMap { try transform($0) }
    }

    func flattenIfPossible<T>(_ unused: Int = 0, _ transform: (Element) throws -> T) rethrows -> Array<T> {
        // Adding an unused argument with a default value to this function's signature allows it to still be
        // an overload of the flattenIfPossible() implementation above, but ranks it lower when
        // the compiler selects an overload.
        // Without the unused argument, the compiler uses this implementation instead of the one above when
        // the element of an array is also an array, which is not desired behavior.
        // See: https://forums.swift.org/t/how-to-specify-which-is-the-default-function-when-functions-use-the-same-name-like-array-reversed/39168/5
        // In the future, if Swift allows us to manually rank overloads or otherwise fixes this issue,
        // we should eliminate this param & use the new mechanism for overload resolution instead.
        return try map { try transform($0) }
    }
}

public enum JMESValue: Equatable, Comparable {
    case number(Double)
    case boolean(Bool)
    case string(String)
    case null

    public init(_ int: Int?) {
        guard let int = int else { self = .null; return }
        self = .number(Double(int))
    }

    public init(_ double: Double?) {
        guard let double = double else { self = .null; return }
        self = .number(double)
    }

    public init(_ bool: Bool?) {
        guard let bool = bool else { self = .null; return }
        self = .boolean(bool)
    }

    public init(_ string: String?) {
        guard let string = string else { self = .null; return }
        self = .string(string)
    }

    public init<T: RawRepresentable>(_ rr: T?) where T.RawValue == String {
        guard let string = rr?.rawValue else { self = .null; return }
        self = .string(string)
    }

    public static func ==(lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.number(let left), .number(let right)):
            return left == right
        case (.boolean(let left), .boolean(let right)):
            return left == right
        case (.string(let left), .string(let right)):
            return left == right
        case (.null, .null):
            return true
        default:
            return false
        }
    }

    public static func <(lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.number(let left), .number(let right)):
            return left < right
        default:
            return false
        }
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension Array {

    /// Flattens an array of arrays down to single depth.
    /// - Parameter transform: A block that transforms the element(s) of this array into an array containing type T.
    /// - Returns: A single-depth array of type T.
    func flattenIfPossible<T>(_ transform: (Element) throws -> Array<T>) rethrows -> Array<T> {
        return try flatMap { try transform($0) }
    }

    /// Returns the receiver mapped to an array of a different, non-array type using the provided transform block.
    /// - Parameters:
    ///   - unused: An unused integer parameter which is used to affect the precedence of selection of overloads by the Swift compiler.
    ///   See discussion in the implementation.
    ///   - transform: A block that transforms each element of the array into a type that is not itself an Array.
    /// - Returns: The receiver, mapped by the `transform` block.
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

/// A value type that is used to facilitate comparison of values returned by JMESPath types, in accordance with the JMESPath spec.
public enum JMESValue: Equatable, Comparable {
    /// A value that is a "number" per the JMESPath spec.
    case number(Double)
    /// A value that is a "boolean" per the JMESPath spec.
    case boolean(Bool)
    /// A value that is a "string" per the JMESPath spec.
    case string(String)
    /// A value that is "null" per the JMESPath spec.
    case null

    /// Creates a `JMESValue` from a Swift `Int`.
    /// - Parameter int: The `Int` to represent as a JMESPath number, or as a JMESPath `null` if `int` is nil.
    public init(_ int: Int?) {
        guard let int = int else { self = .null; return }
        self = .number(Double(int))
    }

    /// Creates a `JMESValue` from a Swift `Double`.
    /// - Parameter double: The `Double` to represent as a JMESPath number, or as a JMESPath `null` if `double` is nil.
    public init(_ double: Double?) {
        guard let double = double else { self = .null; return }
        self = .number(double)
    }

    /// Creates a `JMESValue` from a Swift `Bool`.
    /// - Parameter bool: The `Bool` to represent as a JMESPath Boolean, or as a JMESPath `null` if `bool` is nil.
    public init(_ bool: Bool?) {
        guard let bool = bool else { self = .null; return }
        self = .boolean(bool)
    }

    /// Creates a `JMESValue` from a Swift `String`.
    /// - Parameter string: The `String` to represent as a JMESPath String, or as a JMESPath `null` if `string` is nil.
    public init(_ string: String?) {
        guard let string = string else { self = .null; return }
        self = .string(string)
    }

    /// Creates a `JMESValue` from a type that is raw-representable by a string.
    /// Typically this will be an enumeration of a limited set of expected string values.
    /// The resulting value will be a string for purposes of comparing it to other values.
    /// - Parameter rr: The `RawRepresentable` to represent as a JMESPath String, or as a JMESPath `null` if `rr` is nil.
    public init<T: RawRepresentable>(_ rr: T?) where T.RawValue == String {
        guard let string = rr?.rawValue else { self = .null; return }
        self = .string(string)
    }

    /// Compares two `JMESValue` values, testing for equality per the JMESPath rules.
    /// - Parameters:
    ///   - lhs: The left value
    ///   - rhs: The right value
    /// - Returns: The result of the Swift comparison of the associated values if `lhs` and `rhs` are the same JMESPath type, or `false` otherwise.
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

    /// Compares two `JMESValue` values, testing for order per the JMESPath rules.
    /// Comparison fails if both left and right are not JMESPath numbers.
    /// - Parameters:
    ///   - lhs: The left value
    ///   - rhs: The right value
    /// - Returns: The result of the Swift comparison of the associated values if `lhs` and `rhs` are both JMESPath numbers, or `false` otherwise.
    public static func <(lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.number(let left), .number(let right)):
            return left < right
        default:
            return false
        }
    }
}

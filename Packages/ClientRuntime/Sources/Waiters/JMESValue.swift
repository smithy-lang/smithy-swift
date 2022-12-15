//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

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
    public static func == (lhs: Self, rhs: Self) -> Bool {
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
    /// Returns false if both left and right are not JMESPath numbers.
    /// - Parameters:
    ///   - lhs: The left value
    ///   - rhs: The right value
    /// - Returns: The result of the Swift comparison of the associated values if `lhs` and `rhs` are both JMESPath numbers, or `false` otherwise.
    public static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.number(let left), .number(let right)):
            return left < right
        default:
            return false
        }
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Utility functions for performing comparisons between values in JMESPath expressions.
/// `Bool` may be compared for equality & inequality.
///
/// `String` and a `RawRepresentable where RawValue == String` may be interchangeable compared for equality and inequality.
///
/// `Int` and `Double` may be interchangeably compared for equality, inequality, and order.
///
/// When one of the values in an order comparison is `nil`, the result is `false`.
public enum JMESUtils {

// Function for comparing Bool to Bool.

    public static func test(_ lhs: Bool?, _ comparator: (Bool, Bool) -> Bool, _ rhs: Bool?) -> Bool {
        guard let lhs = lhs, let rhs = rhs else { return false }
        return comparator(lhs, rhs)
    }

// Functions for comparing Double to Double.

    public static func test(_ lhs: Double?, _ comparator: (Double?, Double?) -> Bool, _ rhs: Double?) -> Bool {
        comparator(lhs, rhs)
    }

    public static func test(_ lhs: Double?, _ comparator: (Double, Double) -> Bool, _ rhs: Double?) -> Bool {
        guard let lhs = lhs, let rhs = rhs else { return false }
        return comparator(lhs, rhs)
    }

// Functions for comparing Int to Int.

    public static func test(_ lhs: Int?, _ comparator: (Int?, Int?) -> Bool, _ rhs: Int?) -> Bool {
        comparator(lhs, rhs)
    }

    public static func test(_ lhs: Int?, _ comparator: (Int, Int) -> Bool, _ rhs: Int?) -> Bool {
        guard let lhs = lhs, let rhs = rhs else { return false }
        return comparator(lhs, rhs)
    }

// Function for comparing String to String.

    public static func test(_ lhs: String?, _ comparator: (String?, String?) -> Bool, _ rhs: String?) -> Bool {
        comparator(lhs, rhs)
    }

// Function for comparing two types that are each raw representable by String.

    public static func test<L: RawRepresentable, R: RawRepresentable>(
        _ lhs: L?,
        _ comparator: (String?, String?) -> Bool,
        _ rhs: R?
    ) -> Bool where L.RawValue == String, R.RawValue == String {
        comparator(lhs?.rawValue, rhs?.rawValue)
    }

// Extensions for comparing Int and / or Double.

    public static func test(_ lhs: Int?, _ comparator: (Double?, Double?) -> Bool, _ rhs: Double?) -> Bool {
        comparator(lhs.flatMap { Double($0) }, rhs)
    }

    public static func test(_ lhs: Double?, _ comparator: (Double?, Double?) -> Bool, _ rhs: Int?) -> Bool {
        comparator(lhs, rhs.flatMap { Double($0) })
    }

    public static func test(_ lhs: Int?, _ comparator: (Double, Double) -> Bool, _ rhs: Double?) -> Bool {
        guard let lhs = lhs, let rhs = rhs else { return false }
        return comparator(Double(lhs), rhs)
    }

    public static func test(_ lhs: Double?, _ comparator: (Double, Double) -> Bool, _ rhs: Int?) -> Bool {
        guard let lhs = lhs, let rhs = rhs else { return false }
        return comparator(lhs, Double(rhs))
    }

// Extensions for comparing String with types having raw value of String.

    public static func test<T: RawRepresentable>(
        _ lhs: T?,
        _ comparator: (String?, String?) -> Bool,
        _ rhs: String?
    ) -> Bool where T.RawValue == String {
        comparator(lhs?.rawValue, rhs)
    }

    public static func test<T: RawRepresentable>(
        _ lhs: String?,
        _ comparator: (String?, String?) -> Bool,
        _ rhs: T?
    ) -> Bool where T.RawValue == String {
        comparator(lhs, rhs?.rawValue)
    }
}

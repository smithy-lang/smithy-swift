//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public extension Array {
    func flattenIfPossible() -> Array<Element> {
        return self
    }

    func flattenIfPossible<T>() -> Array<T> where Element == Array<T> {
        return flatMap { $0 }
    }
}

public enum JMESValue: Equatable, Comparable {
    case number(Double)
    case boolean(Bool)
    case string(String)
    case null

    public init(_ int: Int?) {
        if let int = int {
            self = .number(Double(int))
        } else {
            self = .null
        }
    }

    public init(_ double: Double?) {
        if let double = double {
            self = .number(double)
        } else {
            self = .null
        }
    }

    public init(_ bool: Bool?) {
        if let bool = bool {
            self = .boolean(bool)
        } else {
            self = .null
        }
    }

    public init(_ string: String?) {
        if let string = string {
            self = .string(string)
        } else {
            self = .null
        }
    }

    public init<T: RawRepresentable>(_ rr: T?) where T.RawValue == String {
        if let rr = rr {
            self = .string(rr.rawValue)
        } else {
            self = .null
        }
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

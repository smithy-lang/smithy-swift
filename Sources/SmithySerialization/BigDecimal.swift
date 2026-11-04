//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

package import AwsCommonRuntimeKit

/// An immutable, arbitrary-precision decimal.
///
/// Scale is preserved: `"1.50"` is not equal to `"1.5"`.
///
/// Math operations are not supported. Use `toString()` to export the value to a library that does.
public final class BigDecimal: Equatable, CustomStringConvertible, Sendable {
    package let crt: AwsCommonRuntimeKit.BigDecimal

    package init(crt: AwsCommonRuntimeKit.BigDecimal) {
        self.crt = crt
    }

    /// Parses a decimal number: an optional sign, digits, an optional fraction, and an optional exponent.
    /// The grammar is `["-" / "+"] [0-9]+ ["." [0-9]+] ["e" ["-" / "+"] [0-9]+]`. Whitespace is not accepted.
    public convenience init(_ string: String) throws {
        do {
            self.init(crt: try AwsCommonRuntimeKit.BigDecimal(string))
        } catch {
            throw SerializerError("Invalid BigDecimal \"\(string)\": \(error)")
        }
    }

    /// The base-10 representation.
    public func toString() throws -> String {
        do {
            return try crt.toString()
        } catch {
            throw SerializerError("Could not convert BigDecimal to string: \(error)")
        }
    }

    public var description: String { crt.description }

    public static func == (lhs: BigDecimal, rhs: BigDecimal) -> Bool {
        lhs.crt == rhs.crt
    }
}

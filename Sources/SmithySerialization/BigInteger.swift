//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

package import AwsCommonRuntimeKit

/// An immutable, arbitrary-precision signed integer.
///
/// Math operations are not supported. Use `toString()` to export the value to a library that does.
public final class BigInteger: Equatable, CustomStringConvertible, Sendable {
    package let crt: AwsCommonRuntimeKit.BigInteger

    package init(crt: AwsCommonRuntimeKit.BigInteger) {
        self.crt = crt
    }

    /// Parses a base-10 integer. The grammar is `["-" / "+"] [0-9]+`. Whitespace is not accepted.
    public convenience init(_ string: String) throws {
        do {
            self.init(crt: try AwsCommonRuntimeKit.BigInteger(string))
        } catch {
            throw SerializerError("Invalid BigInteger \"\(string)\": \(error)")
        }
    }

    /// The base-10 representation.
    public func toString() throws -> String {
        do {
            return try crt.toString()
        } catch {
            throw SerializerError("Could not convert BigInteger to string: \(error)")
        }
    }

    public var description: String { crt.description }

    public static func == (lhs: BigInteger, rhs: BigInteger) -> Bool {
        lhs.crt == rhs.crt
    }
}

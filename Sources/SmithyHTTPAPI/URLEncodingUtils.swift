//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public enum URLEncodingUtils {

    /// Encodes a URL component for inclusion in the path or query items, using percent-escaping.
    ///
    /// All characters except alphanumerics plus forward slash, underscore, dash, tilde, and period will be escaped.
    public static func urlPercentEncodedForPath(_ string: String) -> String {
        percentEncoded(string, allowingForwardSlash: true)
    }

    /// Encodes a URL component for inclusion in query item name or value, using percent-escaping.
    ///
    /// All characters except alphanumerics plus underscore, dash, tilde, and period will be escaped.
    public static func urlPercentEncodedForQuery(_ string: String) -> String {
        percentEncoded(string, allowingForwardSlash: false)
    }

    public static func encodeNumber<FP: FloatingPoint>(_ value: FP) -> String {
        guard !value.isNaN else { return "NaN" }
        switch value {
        case .infinity:
            return "Infinity"
        case -.infinity:
            return "-Infinity"
        default:
            return "\(value)"
        }
    }

    /// The uppercase hexadecimal digits, as ASCII bytes, used to render a percent escape.
    private static let hexDigits = Array("0123456789ABCDEF".utf8)

    /// Percent-escapes every byte of a string's UTF-8 that isn't allowed in a URL unescaped.
    ///
    /// Returns the string itself when it needs no escaping at all, so the common case allocates nothing.
    private static func percentEncoded(_ string: String, allowingForwardSlash: Bool) -> String {
        let utf8 = string.utf8
        var escapeCount = 0
        for byte in utf8 where !isAllowed(byte, allowingForwardSlash: allowingForwardSlash) {
            escapeCount += 1
        }
        guard escapeCount > 0 else { return string }

        // Each escaped byte grows from one byte to three, i.e. `/` becomes `%2F`.
        var bytes = [UInt8]()
        bytes.reserveCapacity(utf8.count + 2 * escapeCount)
        for byte in utf8 {
            if isAllowed(byte, allowingForwardSlash: allowingForwardSlash) {
                bytes.append(byte)
            } else {
                bytes.append(UInt8(ascii: "%"))
                bytes.append(hexDigits[Int(byte >> 4)])
                bytes.append(hexDigits[Int(byte & 0x0F)])
            }
        }
        // These bytes are a `[UInt8]`, not `Data`, and are ASCII by construction, so the
        // non-failable initializer is correct here.
        // swiftlint:disable:next optional_data_string_conversion
        return String(decoding: bytes, as: UTF8.self)
    }

    /// Returns `true` if this UTF-8 byte need not be percent-encoded in the resulting URL.
    ///
    /// The allowed bytes are the ASCII alphanumerics plus underscore, dash, tilde, and period, and
    /// forward slash when `allowingForwardSlash` is set (for a path, whose segments have already been
    /// joined.)  Every other byte is escaped, including every byte of a multi-byte UTF-8 sequence.
    ///
    /// See, for URL-allowed characters:
    /// https://www.rfc-editor.org/rfc/rfc3986#section-2.3
    @inline(__always)
    private static func isAllowed(_ byte: UInt8, allowingForwardSlash: Bool) -> Bool {
        switch byte {
        case UInt8(ascii: "a")...UInt8(ascii: "z"),
             UInt8(ascii: "A")...UInt8(ascii: "Z"),
             UInt8(ascii: "0")...UInt8(ascii: "9"),
             UInt8(ascii: "_"), UInt8(ascii: "-"), UInt8(ascii: "."), UInt8(ascii: "~"):
            return true
        case UInt8(ascii: "/"):
            return allowingForwardSlash
        default:
            return false
        }
    }
}

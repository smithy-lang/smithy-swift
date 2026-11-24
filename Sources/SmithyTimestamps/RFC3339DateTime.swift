//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// A string that has been validated as an RFC 3339 `date-time`.
///
/// Validation is strict: the string must match `YYYY-MM-DDTHH:MM:SS[.F+](Z|±HH:MM)` exactly, with nothing
/// before or after it, and every field must be in range (including the number of days in the month).
/// Leap seconds (second `60`) are not accepted.
///
/// https://www.rfc-editor.org/rfc/rfc3339#section-5.6
struct RFC3339DateTime {
    /// The validated string with any fractional seconds removed.
    let wholeSecondsString: String

    /// The fractional seconds, truncated to whole milliseconds, in `0...999`.
    let milliseconds: Int

    init?(_ string: String) {
        var utf8String = string
        guard let (offsetStart, milliseconds) = utf8String.withUTF8({ Self.validate($0) }) else { return nil }
        if offsetStart == Self.fractionStart {
            self.wholeSecondsString = string
        } else {
            // A validated string is all ASCII, so UTF-8 offsets are character offsets.
            let utf8 = string.utf8
            let fractionIndex = utf8.index(utf8.startIndex, offsetBy: Self.fractionStart)
            let offsetIndex = utf8.index(utf8.startIndex, offsetBy: offsetStart)
            self.wholeSecondsString = String(string[..<fractionIndex] + string[offsetIndex...])
        }
        self.milliseconds = milliseconds
    }

    /// The position immediately after the whole seconds, where fractional seconds or the offset begin.
    private static let fractionStart = 19

    /// Validates the string's UTF-8 bytes.
    ///
    /// Returns the position where the offset begins and the truncated milliseconds,
    /// or `nil` if the string is not a valid date-time.
    private static func validate(_ bytes: UnsafeBufferPointer<UInt8>) -> (offsetStart: Int, milliseconds: Int)? {
        // Shortest valid string is "YYYY-MM-DDTHH:MM:SSZ"
        guard bytes.count >= 20 else { return nil }

        // Reads `count` digits starting at `index` as an integer, or returns nil if any is not a digit.
        func number(at index: Int, count: Int) -> Int? {
            var value = 0
            for i in index..<(index + count) {
                let digit = Int(bytes[i]) - 0x30
                guard (0...9).contains(digit) else { return nil }
                value = value * 10 + digit
            }
            return value
        }

        // Date & time: YYYY-MM-DDTHH:MM:SS
        guard let year = number(at: 0, count: 4), bytes[4] == UInt8(ascii: "-"),
              let month = number(at: 5, count: 2), bytes[7] == UInt8(ascii: "-"),
              let day = number(at: 8, count: 2), bytes[10] == UInt8(ascii: "T"),
              let hour = number(at: 11, count: 2), bytes[13] == UInt8(ascii: ":"),
              let minute = number(at: 14, count: 2), bytes[16] == UInt8(ascii: ":"),
              let second = number(at: 17, count: 2),
              (1...12).contains(month), (1...daysInMonth(month, year: year)).contains(day),
              (0...23).contains(hour), (0...59).contains(minute), (0...59).contains(second)
        else { return nil }

        // Fractional seconds: "." followed by one or more digits, truncated to milliseconds
        var index = fractionStart
        var milliseconds = 0
        if bytes[index] == UInt8(ascii: ".") {
            index += 1
            let fractionStart = index
            while index < bytes.count, (0x30...0x39).contains(bytes[index]) {
                if index - fractionStart < 3 {
                    milliseconds = milliseconds * 10 + Int(bytes[index]) - 0x30
                }
                index += 1
            }
            let fractionDigits = index - fractionStart
            guard fractionDigits > 0 else { return nil }
            for _ in min(fractionDigits, 3)..<3 { milliseconds *= 10 }
        }
        let offsetStart = index

        // Offset: "Z" or "z", or "+HH:MM" or "-HH:MM", which must end the string
        guard index < bytes.count else { return nil }
        switch bytes[index] {
        case UInt8(ascii: "Z"), UInt8(ascii: "z"):
            guard bytes.count == index + 1 else { return nil }
        case UInt8(ascii: "+"), UInt8(ascii: "-"):
            guard bytes.count == index + 6,
                  let offsetHour = number(at: index + 1, count: 2), bytes[index + 3] == UInt8(ascii: ":"),
                  let offsetMinute = number(at: index + 4, count: 2),
                  (0...23).contains(offsetHour), (0...59).contains(offsetMinute)
            else { return nil }
        default:
            return nil
        }

        return (offsetStart, milliseconds)
    }

    private static func daysInMonth(_ month: Int, year: Int) -> Int {
        switch month {
        case 2:
            let isLeapYear = year % 4 == 0 && (year % 100 != 0 || year % 400 == 0)
            return isLeapYear ? 29 : 28
        case 4, 6, 9, 11:
            return 30
        default:
            return 31
        }
    }
}

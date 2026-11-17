//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if canImport(FoundationEssentials)
import struct FoundationEssentials.Date
import struct FoundationEssentials.TimeZone
#else
import struct Foundation.Date
import struct Foundation.TimeZone
#endif

@available(macOS 12.0, *)
@_spi(SmithyTimestamps)
extension Date.ISO8601FormatStyle {
    /// A format style that converts between dates and the ISO8601 string representation using the date-time production in RFC3339 section 5.6 with no UTC offset and with fractional seconds (for example, 1985-04-12T23:20:50.520Z)
    /// https://xml2rfc.tools.ietf.org/public/rfc/html/rfc3339.html#anchor14
    static let iso8601WithFractionalSeconds = Date.ISO8601FormatStyle(
        includingFractionalSeconds: true,
        timeZone: TimeZone(secondsFromGMT: 0)!
    )

    /// A format style that converts between dates and the ISO8601 string representation using the date-time production in RFC3339 section 5.6 with no UTC offset and without fractional seconds (for example, 1985-04-12T23:20:50Z)
    /// https://xml2rfc.tools.ietf.org/public/rfc/html/rfc3339.html#anchor14
    static let iso8601WithoutFractionalSeconds = Date.ISO8601FormatStyle(
        includingFractionalSeconds: false,
        timeZone: TimeZone(secondsFromGMT: 0)!
    )
}

@_spi(SmithyTimestamps)
extension Date {
    /// Returns a string representation of the date in the ISO8601 format using the date-time production in RFC3339 section 5.6 with no UTC offset and with fractional seconds (for example, 1985-04-12T23:20:50.52Z)
    func iso8601WithFractionalSeconds() -> String {
        if #available(macOS 12.0, *) {
            // ISO8601FormatStyle truncates to milliseconds, while DateFormatter rounds.  Round to the
            // nearest millisecond, then nudge forward by 0.1 ms so that floating point error can't cause
            // truncation to the previous millisecond (i.e. "x.762" must not be formatted as "x.761").
            let nudged = roundedToMilliseconds.addingTimeInterval(0.0001)
            return nudged.formatted(Date.ISO8601FormatStyle.iso8601WithFractionalSeconds)
        } else {
            return legacyISO8601WithFractionalSeconds()
        }
    }
    /// Returns a string representation of the date in the ISO8601 format using the date-time production in RFC3339 section 5.6 with no UTC offset and without fractional seconds (for example, 1985-04-12T23:20:50Z)
    func iso8601WithoutFractionalSeconds() -> String {
        if #available(macOS 12.0, *) {
            return formatted(Date.ISO8601FormatStyle.iso8601WithoutFractionalSeconds)
        } else {
            return legacyISO8601WithoutFractionalSeconds()
        }
    }

    /// Creates a date from an ISO8601 string using the date-time production in RFC3339 section 5.6,
    /// with or without fractional seconds.
    ///
    /// Returns `nil` if the string is not a valid date-time.
    init?(iso8601String string: String) {
        if #available(macOS 12.0, *) {
            // Try with fractional seconds first, then without, since some Foundation versions
            // require the presence of fractional seconds to match the style used to parse.
            // Parsed dates are rounded to milliseconds, matching the precision of DateFormatter.
            if let date = try? Date.ISO8601FormatStyle.iso8601WithFractionalSeconds.parse(string) {
                self = date.roundedToMilliseconds
            } else if let date = try? Date.ISO8601FormatStyle.iso8601WithoutFractionalSeconds.parse(string) {
                self = date.roundedToMilliseconds
            } else {
                return nil
            }
        } else {
            self.init(legacyISO8601String: string)
        }
    }

    /// This date, rounded to the nearest millisecond.
    ///
    /// Rounding is performed relative to the Unix epoch, so that the result is identical to a date
    /// created with `Date(timeIntervalSince1970:)` from a value with millisecond precision.
    var roundedToMilliseconds: Date {
        Date(timeIntervalSince1970: (timeIntervalSince1970 * 1000).rounded() / 1000)
    }
}

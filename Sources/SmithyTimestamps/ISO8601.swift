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
    /// Returns a string representation of the date in the ISO8601 format using the date-time production in RFC3339 section 5.6 with no UTC offset and with fractional seconds (for example, 1985-04-12T23:20:50.520Z)
    ///
    /// Fractional seconds are truncated to milliseconds, as specified for the Smithy `date-time` format.
    func iso8601WithFractionalSeconds() -> String {
        guard let (wholeSeconds, milliseconds) = truncatedToMilliseconds else {
            return iso8601WithoutFractionalSeconds()
        }
        let wholeSecondsDate = Date(timeIntervalSince1970: wholeSeconds)
        if #available(macOS 12.0, *) {
            // Format the whole seconds, then insert the milliseconds before the trailing "Z".
            // Inserting the milliseconds as digits, rather than formatting the fractional date,
            // keeps floating point error from affecting the formatted milliseconds.
            var string = wholeSecondsDate.formatted(Date.ISO8601FormatStyle.iso8601WithoutFractionalSeconds)
            string.removeLast()
            string += milliseconds < 10 ? ".00" : milliseconds < 100 ? ".0" : "."
            string += String(milliseconds)
            string += "Z"
            return string
        } else {
            // DateFormatter rounds to the nearest millisecond, so pass it the exact millisecond.
            let date = Date(timeIntervalSince1970: (wholeSeconds * 1000 + Double(milliseconds)) / 1000)
            return date.legacyISO8601WithFractionalSeconds()
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
    /// The string must strictly match the RFC 3339 `date-time` production, with all fields in range.
    /// Fractional seconds are truncated to milliseconds, as specified for the Smithy `date-time` format.
    ///
    /// Returns `nil` if the string is not a valid date-time.
    init?(iso8601String string: String) {
        // ISO8601FormatStyle ignores content after a valid prefix, and carries out-of-range fields
        // into the next unit (i.e. February 30 becomes March 2), so validate the string first.
        guard let dateTime = RFC3339DateTime(string) else { return nil }
        if #available(macOS 12.0, *) {
            // Parse the string with fractional seconds removed, then add the milliseconds exactly.
            guard let wholeSeconds = try? Date.ISO8601FormatStyle.iso8601WithoutFractionalSeconds.parse(
                dateTime.wholeSecondsString
            ) else { return nil }
            let totalMilliseconds = wholeSeconds.timeIntervalSince1970 * 1000 + Double(dateTime.milliseconds)
            self.init(timeIntervalSince1970: totalMilliseconds / 1000)
        } else {
            guard let date = Date(legacyISO8601String: string) else { return nil }
            self = date.roundedToMilliseconds
        }
    }

    /// This date's whole seconds and milliseconds since the Unix epoch, with fractional milliseconds truncated.
    ///
    /// A margin of 1 microsecond is added before truncating, so that a millisecond value whose binary
    /// representation falls just below the millisecond (i.e. `x.762` stored as `x.76199996`) is not
    /// truncated to the previous millisecond.
    ///
    /// Returns `nil` if this date is not finite.
    private var truncatedToMilliseconds: (wholeSeconds: Double, milliseconds: Int)? {
        let totalMilliseconds = (timeIntervalSince1970 * 1000 + 0.001).rounded(.down)
        guard totalMilliseconds.isFinite else { return nil }
        let wholeSeconds = (totalMilliseconds / 1000).rounded(.down)
        let milliseconds = Int(totalMilliseconds - wholeSeconds * 1000)
        return (wholeSeconds, milliseconds)
    }

    /// This date, rounded to the nearest millisecond.
    ///
    /// Rounding is performed relative to the Unix epoch, so that the result is identical to a date
    /// created with `Date(timeIntervalSince1970:)` from a value with millisecond precision.
    var roundedToMilliseconds: Date {
        Date(timeIntervalSince1970: (timeIntervalSince1970 * 1000).rounded() / 1000)
    }
}

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import struct Foundation.Date
import class Foundation.DateFormatter
import struct Foundation.Locale
import struct Foundation.TimeZone

typealias DateFormatter = Foundation.DateFormatter

@_spi(SmithyTimestamps)
extension DateFormatter {
    /// A date formatter that converts between dates and the IMF-fixdate, with fractional seconds, string representation in RFC 7231#section-7.1.1.1 (for example, Sun, 02 Jan 2000 20:34:56.000 GMT)
    /// https://tools.ietf.org/html/rfc7231.html#section-7.1.1.1
    static let rfc5322WithFractionalSeconds = DateFormatter(fixedFormat: "EE, dd MMM yyyy HH:mm:ss.SSS zzz")

    /// A date formatter that converts between dates and the IMF-fixdate, without fractional seconds, string representation in RFC 7231#section-7.1.1.1 (for example, Tue, 29 Apr 2014 18:30:38 GMT)
    /// https://tools.ietf.org/html/rfc7231.html#section-7.1.1.1
    static let rfc5322WithoutFractionalSeconds = DateFormatter(fixedFormat: "EE, dd MMM yyyy HH:mm:ss zzz")

    /// Used only on platforms where `Date.ISO8601FormatStyle` is unavailable (macOS 11).
    ///
    /// A date formatter that converts between dates and the ISO8601 string representation using the date-time production in RFC3339 section 5.6 with no UTC offset and with fractional seconds (for example, 1985-04-12T23:20:50.52Z)
    /// https://xml2rfc.tools.ietf.org/public/rfc/html/rfc3339.html#anchor14
    static let iso8601DateFormatterWithFractionalSeconds = DateFormatter(
        fixedFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
    )

    /// Used only on platforms where `Date.ISO8601FormatStyle` is unavailable (macOS 11).
    ///
    /// A date formatter that converts between dates and the ISO8601 string representation using the date-time production in RFC3339 section 5.6 with no UTC offset and without fractional seconds (for example, 1985-04-12T23:20:50Z)
    /// https://xml2rfc.tools.ietf.org/public/rfc/html/rfc3339.html#anchor14
    static let iso8601DateFormatterWithoutFractionalSeconds = DateFormatter(
        fixedFormat: "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
    )

    /// Creates a date formatter with a fixed format.
    /// The formatter's locale will be set to `en_US_POSIX` and the time zone to `UTC`
    ///
    /// For more information, see the _Working With Fixed Format Date Representations_ section in:
    ///  https://developer.apple.com/documentation/foundation/dateformatter
    private convenience init(fixedFormat dateFormat: String) {
        self.init()
        self.dateFormat = dateFormat
        self.locale = Locale(identifier: "en_US_POSIX")
        self.timeZone = TimeZone(secondsFromGMT: 0)!
    }
}

@_spi(SmithyTimestamps)
extension Date {
    /// ISO8601 formatting & parsing using `DateFormatter`, for platforms where
    /// `Date.ISO8601FormatStyle` is unavailable (macOS 11).
    func legacyISO8601WithFractionalSeconds() -> String {
        DateFormatter.iso8601DateFormatterWithFractionalSeconds.string(from: self)
    }

    func legacyISO8601WithoutFractionalSeconds() -> String {
        DateFormatter.iso8601DateFormatterWithoutFractionalSeconds.string(from: self)
    }

    init?(legacyISO8601String string: String) {
        self.init(
            from: string,
            formatters: [
                .iso8601DateFormatterWithFractionalSeconds,
                .iso8601DateFormatterWithoutFractionalSeconds
            ]
        )
    }

    /// Creates a date from an IMF-fixdate string per RFC 7231#section-7.1.1.1, with or without fractional seconds.
    ///
    /// The date is rounded to milliseconds so the same instant parsed from date-time & http-date compares equal.
    /// Returns `nil` if the string is not a valid IMF-fixdate.
    init?(rfc5322String string: String) {
        guard let date = Date(
            from: string,
            formatters: [
                .rfc5322WithFractionalSeconds,
                .rfc5322WithoutFractionalSeconds
            ]
        ) else { return nil }
        self = date.roundedToMilliseconds
    }

    /// Creates a date from a string using the given formatters.
    /// The date returned will be from the first formatter, in the given formatters list, that is able to successfully convert the date to a string.
    /// Returns `nil` if the none of the given formatters were able to create a date from the given string or if formatters is empty.
    init?(from string: String, formatters: [DateFormatter]) {
        for formatter in formatters {
            if let date = formatter.date(from: string) {
                self = date
                return
            }
        }
        return nil
    }

    /// Returns a string representation of the date in the IMF-fixdate, with fractional seconds, format in RFC 7231#section-7.1.1.1 (for example, Sun, 02 Jan 2000 20:34:56.000 GMT)
    func rfc5322WithFractionalSeconds() -> String {
        let formatter = DateFormatter.rfc5322WithFractionalSeconds
        return formatter.string(from: self)
    }
    /// Returns a string representation of the date in the  IMF-fixdate, without fractional seconds, format in RFC 7231#section-7.1.1.1 (for example, Tue, 29 Apr 2014 18:30:38 GMT)
    func rfc5322WithoutFractionalSeconds() -> String {
        let formatter = DateFormatter.rfc5322WithoutFractionalSeconds
        return formatter.string(from: self)
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import func Foundation.floor
import struct Foundation.Date

/// Custom timestamp serialization formats
/// https://smithy.io/2.0/spec/protocol-traits.html#smithy-api-timestampformat-trait
public enum TimestampFormat: CaseIterable {
    /// Also known as Unix time, the number of seconds that have elapsed since 00:00:00 Coordinated Universal Time (UTC), Thursday, 1 January 1970, with optional fractional precision (for example, 1515531081.1234).
    case epochSeconds

    /// Date time as defined by the date-time production in RFC3339 section 5.6 with no UTC offset and optional fractional precision (for example, 1985-04-12T23:20:50.52Z).
    case dateTime

    /// An HTTP date as defined by the IMF-fixdate production in RFC 7231#section-7.1.1.1 (for example, Tue, 29 Apr 2014 18:30:38 GMT) with optional fractional seconds (for example, Sun, 02 Jan 2000 20:34:56.000 GMT).
    case httpDate
}

/// A formatter that converts between dates and their smithy timestamp string representations.
public struct TimestampFormatter {
    /// The timestamp serialization format
    let format: TimestampFormat

    /// Creates a formatter for the provided format
    public init(format: TimestampFormat) {
        self.format = format
    }

    /// Creates and returns a smithy timestamp formatted string representation of the specified date.
    /// For each format, the string will only contain fractional seconds if a non-zero value exists for fractional seconds.
    ///
    /// - Parameter date: The date to be represented.
    /// - Returns: A smithy timestamp formatted string representing the date.
    public func string(from date: Date) -> String {
        switch format {
        case .epochSeconds:
            let seconds = date.timeIntervalSince1970
            return date.hasFractionalSeconds
            ? String(seconds)
            : String(format: "%.0f", seconds)
        case .dateTime:
            return date.hasFractionalSeconds
            ? date.iso8601WithFractionalSeconds()
            : date.iso8601WithoutFractionalSeconds()
        case .httpDate:
            return date.hasFractionalSeconds
            ? date.rfc5322WithFractionalSeconds()
            : date.rfc5322WithoutFractionalSeconds()
        }
    }

    /// Creates and returns a date object from the specified smithy timestamp string representation.
    ///
    /// - Parameter string: The smithy timestamp formatted string representation of a date.
    /// - Returns: A date object, or nil if no valid date was found.
    public func date(from string: String) -> Date? {
        // Fractional seconds may be optionally included
        // therfore we need to attempt to get the date using both formatters (with fractional seconds and without)
        switch format {
        case .epochSeconds:
            return Double(string).map(Date.init(timeIntervalSince1970:))
        case .dateTime:
            return Date(
                from: string,
                formatters: [
                    .iso8601DateFormatterWithFractionalSeconds,
                    .iso8601DateFormatterWithoutFractionalSeconds
                ]
            )
        case .httpDate:
            return Date(
                from: string,
                formatters: [
                    .rfc5322WithFractionalSeconds,
                    .rfc5322WithoutFractionalSeconds
                ]
            )
        }
    }
}

extension Date {
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

    /// Returns true if the date contains non-zero values for fractional seconds, otherwise returns false.
    var hasFractionalSeconds: Bool {
        timeIntervalSince1970 != Foundation.floor(timeIntervalSince1970)
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Date
import func Foundation.floor
import enum Smithy.TimestampFormat

@_spi(SmithyTimestamps)
public typealias TimestampFormat = Smithy.TimestampFormat

/// A formatter that converts between dates and their smithy timestamp string representations.
@_spi(SmithyTimestamps)
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
            : String(Int64(seconds))
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
            return SmithyDateFormatter.iso8601DateFormatterWithFractionalSeconds.date(from: string)
                ?? SmithyDateFormatter.iso8601DateFormatterWithoutFractionalSeconds.date(from: string)
        case .httpDate:
            return SmithyDateFormatter.rfc5322WithFractionalSeconds.date(from: string)
                ?? SmithyDateFormatter.rfc5322WithoutFractionalSeconds.date(from: string)
        }
    }
}

@_spi(SmithyTimestamps)
extension Date {
    /// Returns true if the date contains non-zero values for fractional seconds, otherwise returns false.
    var hasFractionalSeconds: Bool {
        timeIntervalSince1970 != Foundation.floor(timeIntervalSince1970)
    }
}

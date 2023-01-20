//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import func Foundation.floor

/// Custom timestamp serialization formats
/// https://awslabs.github.io/smithy/1.0/spec/core/protocol-traits.html#timestampformat-trait
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

// MARK: - Encoding Helpers

/// A struct to encapsulate the encoding logic for Timestamps
struct TimestampEncodable: Encodable {
    let date: Date
    let format: TimestampFormat

    init(date: Date, format: TimestampFormat) {
        self.date = date
        self.format = format
    }

    /// Encodes the date according to the format.
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch format {
        // We want epoch seconds to be encoded as a number and not a string
        case .epochSeconds:
            // If the date doesn't have fractional seconds then encode as an Int
            // so that it doesn't include a `.0` decimal
            date.hasFractionalSeconds
            ? try container.encode(date.timeIntervalSince1970)
            : try container.encode(Int(date.timeIntervalSince1970))
        default:
            let dateString = TimestampFormatter(format: format).string(from: date)
            try container.encode(dateString)
        }
    }
}

extension KeyedEncodingContainer {
    /// Encodes the given date using the given format for the given key.
    ///
    /// - Parameters:
    ///   - date: The date to encode
    ///   - format: The timestamp format to determine how the date is formatted
    ///   - key: The key to associate the date with
    public mutating func encodeTimestamp(
        _ date: Date,
        format: TimestampFormat,
        forKey key: KeyedEncodingContainer<K>.Key
    ) throws {
        let timestamp = TimestampEncodable(date: date, format: format)
        try encode(timestamp, forKey: key)
    }
}

extension SingleValueEncodingContainer {
    /// Encodes the given date using the given format for the given key.
    ///
    /// - Parameters:
    ///   - date: The date to encode
    ///   - format: The timestamp format to determine how the date is formatted
    ///   - key: The key to associate the date with
    public mutating func encodeTimestamp(
        _ date: Date,
        format: TimestampFormat
    ) throws {
        let timestamp = TimestampEncodable(date: date, format: format)
        try encode(timestamp)
    }
}

extension UnkeyedEncodingContainer {
    /// Encodes the given date using the given format for the given key.
    ///
    /// - Parameters:
    ///   - date: The date to encode
    ///   - format: The timestamp format to determine how the date is formatted
    ///   - key: The key to associate the date with
    public mutating func encodeTimestamp(
        _ date: Date,
        format: TimestampFormat
    ) throws {
        let timestamp = TimestampEncodable(date: date, format: format)
        try encode(timestamp)
    }
}

// MARK: - Decoding Helpers

extension KeyedDecodingContainer {
    /// Decodes a date for the given key. It attempts to decode the date using the given format and throws an error if it fails.
    ///
    /// - Parameters:
    ///   - format: The timestamp format to use to decode the date.
    ///   - key: The key that the decoded date is associated with.
    ///
    /// - Returns: A date, if decodable using the provided format.
    ///
    /// - Throws: `DecodingError.dataCorrupted` if the encountered encoded value is not able to be converted to a date using the provided format.
    public func decodeTimestamp(
        _ format: TimestampFormat,
        forKey key: KeyedDecodingContainer<K>.Key
    ) throws -> Date {
        switch format {
        case .epochSeconds:
            let epochSeconds = try decode(Double.self, forKey: key)
            return Date.init(timeIntervalSince1970: epochSeconds)
        case .dateTime, .httpDate:
            let stringValue = try decode(String.self, forKey: key)
            return try timestampStringAsDate(stringValue, format: format, forKey: key)
        }
    }

    /// Decodes a date for the given key. It attempts to decode the date using the given format and throws an error if it fails.
    ///
    /// - Parameters:
    ///   - format: The timestamp format to use to decode the date.
    ///   - key: The key that the decoded date is associated with.
    ///
    /// - Returns: A date, if present for the given key and if decodable using the provided format.
    ///
    /// - Throws: `DecodingError.dataCorrupted` if the encountered encoded value is not able to be converted to a date using the provided format.
    public func decodeTimestampIfPresent(
        _ format: TimestampFormat,
        forKey key: KeyedDecodingContainer<K>.Key
    ) throws -> Date? {
        switch format {
        case .epochSeconds:
            let epochSeconds = try decodeIfPresent(Double.self, forKey: key)
            return epochSeconds.map(Date.init(timeIntervalSince1970:))
        case .dateTime, .httpDate:
            guard let stringValue = try decodeIfPresent(String.self, forKey: key) else {
                return nil
            }
            return try timestampStringAsDate(stringValue, format: format, forKey: key)
        }
    }

    /// Returns a date for the given string of the given format.
    /// Always use this function when decoding a timestamp.
    ///
    /// - Parameters:
    ///   - string: The string to convert to a date
    ///   - format: The timestamp format that the string is represented as.
    ///   - key: The coding key for the corresponding string value when it was decoded. This is used to provide better error messaging in the case where the conversion fails.
    ///
    /// - Returns: A date for the given string of the given format.
    ///
    /// - Throws: `DecodingError.dataCorrupted` if the given string is unable to be converted to a date using the given format.
    public func timestampStringAsDate(
        _ string: String,
        format: TimestampFormat,
        forKey key: KeyedDecodingContainer<K>.Key
    ) throws -> Date {
        guard let date = TimestampFormatter(format: format).date(from: string) else {
            throw DecodingError.timestampError(
                forKey: key,
                in: self,
                dateAsString: string,
                format: format
            )
        }
        return date
    }
}

extension DecodingError {
    static func timestampError<C>(
        forKey key: C.Key,
        in container: C,
        dateAsString: String,
        format: TimestampFormat
    ) -> DecodingError where C: KeyedDecodingContainerProtocol {
        dataCorruptedError(
            forKey: key,
            in: container,
            debugDescription: "Unable to parse: \(dateAsString) using \(format) format"
        )
    }
}

extension ClientRuntime.Date {
    /// Creates a date from a string using the given formatters.
    /// The date returned will be from the first formatter, in the given formatters list, that is able to successfully convert the date to a string.
    /// Returns `nil` if the none of the given formatters were able to create a date from the given string or if formatters is empty.
    init?(from string: String, formatters: [ClientRuntime.DateFormatter]) {
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

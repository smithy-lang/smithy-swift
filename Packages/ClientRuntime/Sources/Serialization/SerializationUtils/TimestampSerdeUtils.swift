//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

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

// MARK: - Encoding Helpers

struct TimestampEncodable: Encodable {
    let date: Date
    let format: TimestampFormat
    
    init(date: Date, format: TimestampFormat) {
        self.date = date
        self.format = format
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch format {
        case .epochSeconds:
            try container.encode(date.timeIntervalSince1970)
        case .dateTime:
            try container.encode(date.iso8601WithFractionalSeconds())
        case .httpDate:
            try container.encode(date.rfc5322WithFractionalSeconds())
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
        switch format {
        case .epochSeconds:
            guard let seconds = Double(string) else {
                throw DecodingError.timestampError(
                    forKey: key,
                    in: self,
                    dateAsString: string,
                    format: .epochSeconds
                )
            }
            return Date(timeIntervalSince1970: seconds)
        case .dateTime:
            guard let date = Date(iso8601: string) else {
                throw DecodingError.timestampError(
                    forKey: key,
                    in: self,
                    dateAsString: string,
                    format: .dateTime
                )
            }
            return date
        case .httpDate:
            guard let date = Date(rfc5322: string) else {
                throw DecodingError.timestampError(
                    forKey: key,
                    in: self,
                    dateAsString: string,
                    format: .httpDate
                )
            }
            return date
        }
    }
}

extension DecodingError {
    static func timestampError<C>(
        forKey key: C.Key,
        in container: C,
        dateAsString: String,
        format: TimestampFormat
    ) -> DecodingError where C : KeyedDecodingContainerProtocol {
        dataCorruptedError(
            forKey: key,
            in: container,
            debugDescription: "Unable to parse: \(dateAsString) using \(format) format"
        )
    }
}

extension ClientRuntime.Date {
    /// Creates a date from a string in the ISO8601 respresentation.
    /// This ensures a non-nil date is created regardless if the string contains fractional seconds or not.
    /// Returns `nil` if it fails to create a date which usually means the string is not in a valid ISO8601 format
    init?(iso8601: String) {
        guard let date = Date(
            from: iso8601,
            formatters: [
                .iso8601DateFormatterWithFractionalSeconds,
                .iso8601DateFormatterWithoutFractionalSeconds
            ]
        ) else { return nil }
        self = date
    }
    
    /// Creates a date from a string in the RFC5322 respresentation.
    /// This ensures a non-nil date is created regardless if the string contains fractional seconds or not.
    /// Returns `nil` if it fails to create a date which usually means the string is not in a valid RFC5322 format
    init?(rfc5322: String) {
        guard let date = Date(
            from: rfc5322,
            formatters: [
                .rfc5322WithFractionalSeconds,
                .rfc5322WithoutFractionalSeconds
            ]
        ) else { return nil }
        self = date
    }
    
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
}

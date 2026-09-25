/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

#if canImport(Darwin)
// swiftlint:disable:next unused_import
import Darwin
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#else
// The wording matches the diagnostic in ClientRuntime's PlatformOperatingSystem, which the lint
// workflow filters out of the compiler log it feeds to SwiftLint's analyzer.
#error("Cannot use a an operating system we do not support")
#endif

import struct Foundation.Date

/// Converts between `Date` and the fixed-format date representations used by Smithy protocols.
///
/// Formatting is performed with the C library's `strftime`.  It reads weekday and month names from
/// the process's `LC_TIME` locale, so the `%a` and `%b` specifiers are not used; names are rendered
/// from the tables on this type instead, keeping output independent of the host locale.
///
/// Parsing is performed by the scanning routines on this type rather than by `strptime`, which
/// Swift does not expose on every supported platform, and whose whitespace and range handling
/// varies between C libraries.
struct SmithyDateFormatter: Sendable {

    /// The overall shape of the date representation.
    enum Layout: Sendable {
        /// The IMF-fixdate production in RFC 7231 section 7.1.1.1 (for example, Tue, 29 Apr 2014 18:30:38 GMT)
        case rfc5322
        /// The date-time production in RFC 3339 section 5.6 (for example, 1985-04-12T23:20:50Z)
        case iso8601
    }

    /// The overall shape of the date representation.
    let layout: Layout

    /// Whether the representation carries a fractional seconds component.
    ///
    /// A formatter only converts dates whose representation matches this setting; a formatter that
    /// includes fractional seconds will not parse a string that omits them, and vice versa.
    let includesFractionalSeconds: Bool

    /// A formatter for the IMF-fixdate, with fractional seconds, string representation in RFC 7231#section-7.1.1.1 (for example, Sun, 02 Jan 2000 20:34:56.000 GMT)
    /// https://tools.ietf.org/html/rfc7231.html#section-7.1.1.1
    static let rfc5322WithFractionalSeconds = SmithyDateFormatter(
        layout: .rfc5322,
        includesFractionalSeconds: true
    )

    /// A formatter for the IMF-fixdate, without fractional seconds, string representation in RFC 7231#section-7.1.1.1 (for example, Tue, 29 Apr 2014 18:30:38 GMT)
    /// https://tools.ietf.org/html/rfc7231.html#section-7.1.1.1
    static let rfc5322WithoutFractionalSeconds = SmithyDateFormatter(
        layout: .rfc5322,
        includesFractionalSeconds: false
    )

    /// A formatter for the ISO8601 string representation using the date-time production in RFC3339 section 5.6 with no UTC offset and with fractional seconds (for example, 1985-04-12T23:20:50.52Z)
    /// https://xml2rfc.tools.ietf.org/public/rfc/html/rfc3339.html#anchor14
    static let iso8601DateFormatterWithFractionalSeconds = SmithyDateFormatter(
        layout: .iso8601,
        includesFractionalSeconds: true
    )

    /// A formatter for the ISO8601 string representation using the date-time production in RFC3339 section 5.6 with no UTC offset and without fractional seconds (for example, 1985-04-12T23:20:50Z)
    /// https://xml2rfc.tools.ietf.org/public/rfc/html/rfc3339.html#anchor14
    static let iso8601DateFormatterWithoutFractionalSeconds = SmithyDateFormatter(
        layout: .iso8601,
        includesFractionalSeconds: false
    )

    // MARK: - Names & zones

    private static let weekdayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    private static let monthNames = [
        "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
    ]

    /// The named zones defined by the obs-zone production in RFC 5322 section 4.3, plus the `Z`
    /// military zone.  Any other alphabetic zone name is treated as UTC, as that section directs.
    private static let namedZones: [(name: String, offset: Int)] = [
        ("GMT", 0), ("UTC", 0), ("UT", 0), ("Z", 0),
        ("EST", -5 * 3600), ("EDT", -4 * 3600),
        ("CST", -6 * 3600), ("CDT", -5 * 3600),
        ("MST", -7 * 3600), ("MDT", -6 * 3600),
        ("PST", -8 * 3600), ("PDT", -7 * 3600),
    ]

    // MARK: - Formatting

    /// Creates and returns a string representation of the specified date in this formatter's layout.
    ///
    /// - Parameter date: The date to be represented.
    /// - Returns: A string representing the date, in UTC, or an empty string if the date is too far
    ///   from the epoch to fall on a representable calendar date.
    func string(from date: Date) -> String {
        let interval = date.timeIntervalSince1970
        // A `Date` can hold intervals whose year overflows the `tm` fields; those have no
        // representation in either layout.
        guard interval.isFinite, interval.magnitude < 6.7e16 else { return "" }
        var wholeSeconds = interval.rounded(.down)
        var milliseconds = Int(((interval - wholeSeconds) * 1000).rounded())
        // Rounding the fraction up to a full second carries into the seconds component.
        if milliseconds >= 1000 {
            milliseconds -= 1000
            wholeSeconds += 1
        }

        // Decompose in Int64: time_t is 32 bits on some platforms (watchOS arm64_32), but the
        // guard above only bounds the interval to the tm_year range.
        let total = Int64(wholeSeconds)
        var days = total / 86400
        var secondsOfDay = total % 86400
        if secondsOfDay < 0 {
            secondsOfDay += 86400
            days -= 1
        }

        let (year, month, day) = Self.civilFromDays(days)
        var components = tm()
        components.tm_year = Int32(year - 1900)
        components.tm_mon = Int32(month - 1)
        components.tm_mday = Int32(day)
        components.tm_hour = Int32(secondsOfDay / 3600)
        components.tm_min = Int32((secondsOfDay % 3600) / 60)
        components.tm_sec = Int32(secondsOfDay % 60)
        components.tm_wday = Int32(((days % 7) + 11) % 7)  // day 0, 1970-01-01, was a Thursday

        let format: String
        switch layout {
        case .rfc5322:
            format = Self.rfc5322Formats[Int(components.tm_wday) * 12 + Int(components.tm_mon)]
        case .iso8601:
            format = Self.iso8601Format
        }

        let suffix: String
        switch (layout, includesFractionalSeconds) {
        case (.rfc5322, true): suffix = ".\(Self.paddedMilliseconds(milliseconds)) GMT"
        case (.rfc5322, false): suffix = " GMT"
        case (.iso8601, true): suffix = ".\(Self.paddedMilliseconds(milliseconds))Z"
        case (.iso8601, false): suffix = "Z"
        }

        var buffer = [UInt8](repeating: 0, count: 64)
        let count = buffer.withUnsafeMutableBytes { bytes in
            let characters = bytes.bindMemory(to: CChar.self)
            return strftime(characters.baseAddress!, characters.count, format, &components)
        }
        guard count > 0 else { return "" }
        // swiftlint:disable:next optional_data_string_conversion
        var formatted = String(decoding: buffer[0..<count], as: UTF8.self)
        Self.padYear(in: &formatted, of: components, layout: layout)
        return formatted + suffix
    }

    private static let iso8601Format = "%Y-%m-%dT%H:%M:%S"

    /// One `strftime` format per weekday & month pair, indexed by `tm_wday * 12 + tm_mon`, so that
    /// formatting a date does not have to build a format string.
    private static let rfc5322Formats: [String] = weekdayNames.flatMap { weekday in
        monthNames.map { month in "\(weekday), %d \(month) %Y %H:%M:%S" }
    }

    /// The offset at which the year begins in each layout's formatted output.  Every component
    /// ahead of the year is fixed-width in both layouts, so these offsets are constant.
    private static func yearOffset(in layout: Layout) -> Int {
        switch layout {
        case .rfc5322: return 12 // "Xxx, DD Xxx "
        case .iso8601: return 0
        }
    }

    /// Zero-pads the year in already-formatted output out to the four digits that both RFC 7231 and
    /// RFC 3339 require.
    ///
    /// `strftime`'s `%Y` pads the year on Darwin but not on Linux, so however many digits it wrote
    /// are counted rather than assumed.
    private static func padYear(in formatted: inout String, of components: tm, layout: Layout) {
        let year = Int(components.tm_year) + 1900
        guard year >= 0, year < 1000 else { return }
        let offset = yearOffset(in: layout)
        guard let start = formatted.index(
            formatted.startIndex,
            offsetBy: offset,
            limitedBy: formatted.endIndex
        ) else { return }
        var index = start
        var digitCount = 0
        while index < formatted.endIndex, formatted[index].isNumber {
            digitCount += 1
            index = formatted.index(after: index)
        }
        guard digitCount < 4 else { return }
        formatted.insert(contentsOf: String(repeating: "0", count: 4 - digitCount), at: start)
    }

    private static func paddedMilliseconds(_ milliseconds: Int) -> String {
        let digits = String(milliseconds)
        return String(repeating: "0", count: max(0, 3 - digits.count)) + digits
    }

    // MARK: - Parsing

    /// Creates and returns a date from the specified string, which must be in this formatter's layout.
    ///
    /// - Parameter string: The string representation of a date.
    /// - Returns: A date object, or `nil` if the string is not a date in this formatter's layout.
    func date(from string: String) -> Date? {
        string.withCString { start -> Date? in
            var cursor = start
            let year: Int, month: Int, day: Int

            switch layout {
            case .rfc5322:
                // The weekday is validated but otherwise unused; RFC 7231 permits it to disagree
                // with the rest of the date, and the previous Foundation-based implementation
                // ignored it as well.
                guard Self.scanName(&cursor, in: Self.weekdayNames) != nil else { return nil }
                guard Self.scan(&cursor, ascii: ","), Self.scan(&cursor, ascii: " ") else { return nil }
                guard let scannedDay = Self.scanNumber(&cursor, digits: 2, in: 1...31) else { return nil }
                guard Self.scan(&cursor, ascii: " ") else { return nil }
                guard let monthIndex = Self.scanName(&cursor, in: Self.monthNames) else { return nil }
                guard Self.scan(&cursor, ascii: " ") else { return nil }
                guard let scannedYear = Self.scanNumber(&cursor, digits: 4, in: 0...9999) else { return nil }
                guard Self.scan(&cursor, ascii: " ") else { return nil }
                (year, month, day) = (scannedYear, monthIndex + 1, scannedDay)
            case .iso8601:
                guard let scannedYear = Self.scanNumber(&cursor, digits: 4, in: 0...9999) else { return nil }
                guard Self.scan(&cursor, ascii: "-") else { return nil }
                guard let scannedMonth = Self.scanNumber(&cursor, digits: 2, in: 1...12) else { return nil }
                guard Self.scan(&cursor, ascii: "-") else { return nil }
                guard let scannedDay = Self.scanNumber(&cursor, digits: 2, in: 1...31) else { return nil }
                guard Self.scan(&cursor, ascii: "T") else { return nil }
                (year, month, day) = (scannedYear, scannedMonth, scannedDay)
            }

            guard let hour = Self.scanNumber(&cursor, digits: 2, in: 0...23) else { return nil }
            guard Self.scan(&cursor, ascii: ":") else { return nil }
            guard let minute = Self.scanNumber(&cursor, digits: 2, in: 0...59) else { return nil }
            guard Self.scan(&cursor, ascii: ":") else { return nil }
            guard let second = Self.scanNumber(&cursor, digits: 2, in: 0...59) else { return nil }

            var fraction = 0.0
            if includesFractionalSeconds {
                guard let scanned = Self.scanFraction(&cursor) else { return nil }
                fraction = scanned
            }

            guard let offset = Self.scanZone(&cursor, layout: layout) else { return nil }
            // Reject any trailing content; a partial match is not a date.
            guard cursor.pointee == 0 else { return nil }

            let seconds = Self.secondsSinceEpoch(
                year: year, month: month, day: day, hour: hour, minute: minute, second: second
            )
            return Date(timeIntervalSince1970: seconds - Double(offset) + fraction)
        }
    }

    /// Returns the number of seconds between the epoch and the given UTC date and time.
    ///
    /// `timegm` is not used for this because it fails for years before 1900, and signals failure by
    /// returning `-1`, which is also a valid time.
    private static func secondsSinceEpoch(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        second: Int
    ) -> Double {
        let days = daysFromCivil(year: Int64(year), month: Int64(month), day: Int64(day))
        return Double(days) * 86400
            + Double(hour) * 3600
            + Double(minute) * 60
            + Double(second)
    }

    /// Returns the number of days between 1970-01-01 and the given proleptic Gregorian date.
    ///
    /// Adapted from the `days_from_civil` algorithm at
    /// https://howardhinnant.github.io/date_algorithms.html
    private static func daysFromCivil(year: Int64, month: Int64, day: Int64) -> Int64 {
        // Shift the year so that it begins in March, placing the leap day at the end of the year.
        let shiftedYear = year - (month <= 2 ? 1 : 0)
        let era = (shiftedYear >= 0 ? shiftedYear : shiftedYear - 399) / 400
        let yearOfEra = shiftedYear - era * 400                                        // [0, 399]
        let dayOfYear = (153 * (month + (month > 2 ? -3 : 9)) + 2) / 5 + day - 1       // [0, 365]
        let dayOfEra = yearOfEra * 365 + yearOfEra / 4 - yearOfEra / 100 + dayOfYear   // [0, 146096]
        // 719468 is the number of days from 0000-03-01 to 1970-01-01.
        return era * 146097 + dayOfEra - 719468
    }

    /// Returns the proleptic Gregorian date that falls `days` days after 1970-01-01.
    ///
    /// Adapted from the `civil_from_days` algorithm at
    /// https://howardhinnant.github.io/date_algorithms.html
    private static func civilFromDays(_ days: Int64) -> (year: Int64, month: Int64, day: Int64) {
        // 719468 is the number of days from 0000-03-01 to 1970-01-01.
        let z = days + 719468
        let era = (z >= 0 ? z : z - 146096) / 146097
        let dayOfEra = z - era * 146097                                                    // [0, 146096]
        let yearOfEra = (dayOfEra - dayOfEra / 1460 + dayOfEra / 36524 - dayOfEra / 146096) / 365 // [0, 399]
        let dayOfYear = dayOfEra - (365 * yearOfEra + yearOfEra / 4 - yearOfEra / 100)     // [0, 365]
        let monthFromMarch = (5 * dayOfYear + 2) / 153                                     // [0, 11]
        let day = dayOfYear - (153 * monthFromMarch + 2) / 5 + 1                           // [1, 31]
        let month = monthFromMarch < 10 ? monthFromMarch + 3 : monthFromMarch - 9          // [1, 12]
        return (yearOfEra + era * 400 + (month <= 2 ? 1 : 0), month, day)
    }

    /// Advances the cursor past one date or time component of up to `digits` digits.
    ///
    /// The cursor is left unmoved unless the component both parses and falls within `range`, so
    /// that a value out of range is rejected rather than leaving the cursor mid-component.
    ///
    /// - Returns: The component's value, or `nil` if the cursor is not at a digit or the value
    ///   falls outside `range`.
    private static func scanNumber(
        _ cursor: inout UnsafePointer<CChar>,
        digits: Int,
        in range: ClosedRange<Int>
    ) -> Int? {
        var candidate = cursor
        guard let value = scanDigits(&candidate, maximum: digits), range.contains(value) else {
            return nil
        }
        cursor = candidate
        return value
    }

    /// Advances the cursor past `character` if it is the next character.
    private static func scan(_ cursor: inout UnsafePointer<CChar>, ascii character: Unicode.Scalar) -> Bool {
        guard cursor.pointee == CChar(bitPattern: UInt8(ascii: character)) else { return false }
        cursor += 1
        return true
    }

    /// Advances the cursor past `text` if it is the next content.  Matching is case-sensitive.
    private static func scan(_ cursor: inout UnsafePointer<CChar>, text: String) -> Bool {
        var candidate = cursor
        for byte in text.utf8 {
            guard candidate.pointee == CChar(bitPattern: byte) else { return false }
            candidate += 1
        }
        cursor = candidate
        return true
    }

    /// Advances the cursor past the next of `names` to match at it.
    ///
    /// - Returns: The index of the matched name, or `nil` if none matched.
    private static func scanName(_ cursor: inout UnsafePointer<CChar>, in names: [String]) -> Int? {
        for (index, name) in names.enumerated() where scan(&cursor, text: name) {
            return index
        }
        return nil
    }

    /// Advances the cursor past a decimal point and the digits following it.
    ///
    /// - Returns: The digits as a fraction of a second, or `nil` if the cursor is not at a decimal
    ///   point followed by at least one digit.
    private static func scanFraction(_ cursor: inout UnsafePointer<CChar>) -> Double? {
        guard scan(&cursor, ascii: ".") else { return nil }
        var value = 0.0
        var divisor = 1.0
        var digitCount = 0
        while let digit = digit(cursor.pointee) {
            // Digits past nanosecond precision cannot affect the result, so only their presence
            // is recorded.
            if digitCount < 9 {
                value = value * 10 + Double(digit)
                divisor *= 10
            }
            digitCount += 1
            cursor += 1
        }
        guard digitCount > 0 else { return nil }
        return value / divisor
    }

    /// Advances the cursor past the zone designator, and any whitespace preceding it.
    ///
    /// - Returns: The zone's offset from UTC in seconds, or `nil` if the cursor is not at a zone
    ///   designator valid for `layout`.
    private static func scanZone(_ cursor: inout UnsafePointer<CChar>, layout: Layout) -> Int? {
        while scan(&cursor, ascii: " ") {}
        if cursor.pointee == CChar(bitPattern: UInt8(ascii: "+"))
            || cursor.pointee == CChar(bitPattern: UInt8(ascii: "-")) {
            return scanNumericOffset(&cursor)
        }
        switch layout {
        case .rfc5322:
            return scanNamedZone(&cursor)
        case .iso8601:
            // RFC 3339 spells UTC as `Z`; the lowercase form is accepted too, as it was by the
            // previous Foundation-based implementation.
            return scan(&cursor, ascii: "Z") || scan(&cursor, ascii: "z") ? 0 : nil
        }
    }

    /// Advances the cursor past a signed numeric offset such as `+00:00`, `-0500`, or `+005001`.
    ///
    /// - Returns: The offset from UTC in seconds, or `nil` if the cursor is not at an offset.
    private static func scanNumericOffset(_ cursor: inout UnsafePointer<CChar>) -> Int? {
        let isNegative = cursor.pointee == CChar(bitPattern: UInt8(ascii: "-"))
        cursor += 1
        guard let hours = scanDigits(&cursor, maximum: 2) else { return nil }
        var offset = hours * 3600
        // Minutes and seconds are optional, and may or may not be colon-separated.
        if let minutes = scanOffsetComponent(&cursor) {
            offset += minutes * 60
            if let seconds = scanOffsetComponent(&cursor) {
                offset += seconds
            }
        }
        return isNegative ? -offset : offset
    }

    /// Advances the cursor past an optional colon followed by the minutes or seconds of an offset.
    private static func scanOffsetComponent(_ cursor: inout UnsafePointer<CChar>) -> Int? {
        var candidate = cursor
        _ = scan(&candidate, ascii: ":")
        guard let value = scanDigits(&candidate, maximum: 2) else { return nil }
        cursor = candidate
        return value
    }

    /// Advances the cursor past an alphabetic zone name.
    ///
    /// - Returns: The named zone's offset from UTC in seconds, zero for an unrecognized name, or
    ///   `nil` if the cursor is not at an alphabetic character.
    private static func scanNamedZone(_ cursor: inout UnsafePointer<CChar>) -> Int? {
        guard isAlphabetic(cursor.pointee) else { return nil }
        for zone in namedZones {
            var candidate = cursor
            // A name only matches if it consumes the whole run of letters, so that, for example,
            // `UT` does not match the first two letters of `UTC`.
            guard scan(&candidate, text: zone.name), !isAlphabetic(candidate.pointee) else { continue }
            cursor = candidate
            return zone.offset
        }
        while isAlphabetic(cursor.pointee) { cursor += 1 }
        return 0
    }

    /// Advances the cursor past up to `maximum` digits.
    ///
    /// - Returns: The digits' value, or `nil` if the cursor is not at a digit.
    private static func scanDigits(_ cursor: inout UnsafePointer<CChar>, maximum: Int) -> Int? {
        var value = 0
        var digitCount = 0
        while digitCount < maximum, let digit = digit(cursor.pointee) {
            value = value * 10 + digit
            digitCount += 1
            cursor += 1
        }
        return digitCount > 0 ? value : nil
    }

    private static func digit(_ character: CChar) -> Int? {
        let zero = CChar(bitPattern: UInt8(ascii: "0"))
        guard character >= zero, character <= CChar(bitPattern: UInt8(ascii: "9")) else { return nil }
        return Int(character - zero)
    }

    private static func isAlphabetic(_ character: CChar) -> Bool {
        let uppercase = CChar(bitPattern: UInt8(ascii: "A"))...CChar(bitPattern: UInt8(ascii: "Z"))
        let lowercase = CChar(bitPattern: UInt8(ascii: "a"))...CChar(bitPattern: UInt8(ascii: "z"))
        return uppercase.contains(character) || lowercase.contains(character)
    }
}

@_spi(SmithyTimestamps)
extension Date {
    /// Returns a string representation of the date in the ISO8601 format using the date-time production in RFC3339 section 5.6 with no UTC offset and with fractional seconds (for example, 1985-04-12T23:20:50.52Z)
    func iso8601WithFractionalSeconds() -> String {
        SmithyDateFormatter.iso8601DateFormatterWithFractionalSeconds.string(from: self)
    }
    /// Returns a string representation of the date in the ISO8601 format using the date-time production in RFC3339 section 5.6 with no UTC offset and without fractional seconds (for example, 1985-04-12T23:20:50Z)
    func iso8601WithoutFractionalSeconds() -> String {
        SmithyDateFormatter.iso8601DateFormatterWithoutFractionalSeconds.string(from: self)
    }
    /// Returns a string representation of the date in the IMF-fixdate, with fractional seconds, format in RFC 7231#section-7.1.1.1 (for example, Sun, 02 Jan 2000 20:34:56.000 GMT)
    func rfc5322WithFractionalSeconds() -> String {
        SmithyDateFormatter.rfc5322WithFractionalSeconds.string(from: self)
    }
    /// Returns a string representation of the date in the  IMF-fixdate, without fractional seconds, format in RFC 7231#section-7.1.1.1 (for example, Tue, 29 Apr 2014 18:30:38 GMT)
    func rfc5322WithoutFractionalSeconds() -> String {
        SmithyDateFormatter.rfc5322WithoutFractionalSeconds.string(from: self)
    }
}

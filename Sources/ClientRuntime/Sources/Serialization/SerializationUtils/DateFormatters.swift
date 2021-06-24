/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import class Foundation.DateFormatter
import struct Foundation.TimeZone
import struct Foundation.Locale

public typealias DateFormatter = Foundation.DateFormatter

extension DateFormatter {
    /*
    Configures RFC 5322(822) Date Formatter
    https://tools.ietf.org/html/rfc7231.html#section-7.1.1.1
    */
    public static let rfc5322DateFormatter: DateFormatter =
        getDateFormatter(
            dateFormat: "EE, dd MMM yyyy HH:mm:ss zzz",
            timeZone: TimeZone(secondsFromGMT: 0)!
    )
    
    /*
    Configures ISO 8601 Date Formatter With Fractional Seconds
    https://xml2rfc.tools.ietf.org/public/rfc/html/rfc3339.html#anchor14
    */
    public static let iso8601DateFormatterWithFractionalSeconds =
        getDateFormatter(
            dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            timeZone: TimeZone(secondsFromGMT: 0)!
    )
    
    /*
    Configures default ISO 8601 Date Formatter
    https://xml2rfc.tools.ietf.org/public/rfc/html/rfc3339.html#anchor14
    */
    public static let iso8601DateFormatterWithoutFractionalSeconds: DateFormatter =
        getDateFormatter(
            dateFormat: "yyyy-MM-dd'T'HH:mm:ssZZZZZ",
            timeZone: TimeZone(secondsFromGMT: 0)!
    )
    
    private static func getDateFormatter(dateFormat: String, timeZone: TimeZone) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        return formatter
    }
}

public extension Date {
    func iso8601FractionalSeconds() -> String {
        let formatter = DateFormatter.iso8601DateFormatterWithFractionalSeconds
        return formatter.string(from: self)
    }
    func iso8601WithoutFractionalSeconds() -> String {
        let formatter = DateFormatter.iso8601DateFormatterWithoutFractionalSeconds
        return formatter.string(from: self)
    }
    func rfc5322() -> String {
        let formatter = DateFormatter.rfc5322DateFormatter
        return formatter.string(from: self)
    }
}

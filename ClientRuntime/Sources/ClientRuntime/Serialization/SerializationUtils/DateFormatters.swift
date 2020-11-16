//
// Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

import Foundation

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

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
    public static let rfc5322DateFormatter: DateFormatter = getDateFormatter(dateFormat: "EE, dd MMM yyyy HH:mm:ss zzz",
                                                                             timeZone: TimeZone(abbreviation: "GMT"))
    
    /*
    Configures ISO 8601 Date Formatter With Fractional Seconds
    https://xml2rfc.tools.ietf.org/public/rfc/html/rfc3339.html#anchor14
    */
    public static let iso8601DateFormatterWithFractionalSeconds: DateFormatter = getDateFormatter(dateFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                                                                                                  timeZone: TimeZone(abbreviation: "GMT"))
    
    
    
    /*
    Configures default ISO 8601 Date Formatter
    https://xml2rfc.tools.ietf.org/public/rfc/html/rfc3339.html#anchor14
    */
    public static let iso8601DateFormatterWithoutFractionalSeconds: DateFormatter = getDateFormatter(dateFormat: "yyyy-MM-dd'T'HH:mm:ssZ",
                                                                                                     timeZone: TimeZone(abbreviation: "GMT"))
    
    /*
    Configures an Epoch Seconds based formatter.
    Based on the number of seconds that have elapsed since 00:00:00 Coordinated Universal Time (UTC), Thursday, 1 January 1970
    */
    public static let epochSecondsDateFormatter: EpochSecondsDateFormatter = {
        return EpochSecondsDateFormatter()
    }()
    
    private static func getDateFormatter(dateFormat: String, timeZone: TimeZone? = nil) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timeZone
        return formatter
    }
    
    public func string(from date: ISO8601Date) -> String {
        return string(from: date.value)
    }

    public func string(from date: RFC5322Date) -> String {
        return string(from: date.value)
    }

    public func string(from date: EpochSecondsDate) -> String {
        return string(from: date.value)
    }
}

/*
 Configures an Epoch Seconds based formatter.
 Based on the number of seconds that have elapsed since 00:00:00 Coordinated Universal Time (UTC), Thursday, 1 January 1970
 */
public class EpochSecondsDateFormatter: DateFormatter {
    public override func date(from string: String) -> Date? {
        guard let double = Double(string) else {
            return nil
        }
        return date(from: double)
    }
    
    public override func string(from date: Date) -> String {
        return String(date.timeIntervalSince1970)
    }
    
    public func date(from double: Double) -> Date? {
        return Date(timeIntervalSince1970: double)
    }
    
    public func double(from date: Date) -> Double {
        return date.timeIntervalSince1970
    }
}

enum DateDecodingError: Error {
    case parseError
}

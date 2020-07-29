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

/*
 Configures RFC 7231 Date Formatter
 https://tools.ietf.org/html/rfc7231.html#section-7.1.1.1
 */
public func getRFC7231DateFormatter() -> DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "EE, dd MMM yyyy HH:mm:ss zzz"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(abbreviation: "GMT")
    return formatter
}

/*
Configures ISO 8601 Date Formatter With Fractional Seconds
https://xml2rfc.tools.ietf.org/public/rfc/html/rfc3339.html#anchor14
*/
public func getISO8601DateFormatterWithFractionalSeconds() -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}

/*
Configures ISO 8601 Date Formatter
https://xml2rfc.tools.ietf.org/public/rfc/html/rfc3339.html#anchor14
*/
public func getISO8601DateFormatterWithoutFractionalSeconds() -> ISO8601DateFormatter {
    let formatter = ISO8601DateFormatter()
    return formatter
}


public protocol DateFormatterProtocol {
    func date(from string: String) -> Date?
    func string(from date: Date) -> String
}

extension DateFormatter: DateFormatterProtocol {}
extension ISO8601DateFormatter: DateFormatterProtocol {}

/*
 Configures an Eposch Seconds based formatter.
 Based on the number of seconds that have elapsed since 00:00:00 Coordinated Universal Time (UTC), Thursday, 1 January 1970
 */
struct EposchSecondsDateFormatter: DateFormatterProtocol {
    func date(from string: String) -> Date? {
        guard let double = Double(string) else {
            return nil
        }
        return Date(timeIntervalSince1970: double)
    }
    
    func string(from date: Date) -> String {
        return String(date.timeIntervalSince1970)
    }
    
    func date(from double: Double) -> Date? {
        return Date(timeIntervalSince1970: double)
    }
    
    func string(from date: Date) -> Double {
        return date.timeIntervalSince1970
    }
}

enum DateDecodingError: Error {
    case parseError
}

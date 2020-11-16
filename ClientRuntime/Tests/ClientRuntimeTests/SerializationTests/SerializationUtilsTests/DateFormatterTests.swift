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

import XCTest
@testable import ClientRuntime

class DateFormatterTests: XCTestCase {
    
    var testDateFormatter: DateFormatter = DateFormatter()

    func testCreateDateFromValidRFC5322String() {
        let validDates = [
            // standard
            "Sun, 20 Nov 1993 05:45:1 GMT":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 05, minute: 45, second: 1),
            // different timeZone from default GMT
             "Mon, 20 Nov 1993 05:45:1 CST":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 11, minute: 45, second: 1),
             "Tue, 1 Nov 1993 05:45:10 GMT":
                ExpectedDateComponents(day: 1, month: 11, year: 1993, hour: 05, minute: 45, second: 10),
             // Different offset specs
             "Tue, 20 Nov 1993 05:45:10 +0000":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 05, minute: 45, second: 10),
             "Tue, 20 Nov 1993 05:45:00 -0015":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 06, minute: 0, second: 0),
             "Mon, 20 Nov 1993 14:02:02 +000":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 14, minute: 2, second: 2),
             // default to GMT for unknown timeZones
             "Tue, 20 Nov 1993 05:45:10 UT":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 05, minute: 45, second: 10),
             "Tue, 20 Nov 1993 05:45:10 Z":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 05, minute: 45, second: 10),
             // components without padding
             "Mon, 20 Nov 193 05:45:10 GMT":
                ExpectedDateComponents(day: 20, month: 11, year: 193, hour: 05, minute: 45, second: 10),
             "Mon, 20 Nov 1993 4:2:7 GMT":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 4, minute: 2, second: 7)
             
        ]
        
        let formatter = DateFormatter.rfc5322DateFormatter
        
        for (dateString, dateComponents) in validDates {
            guard let constructedDate = formatter.date(from: dateString) else {
                XCTFail("could not parse RFC7231 string: \(dateString)")
                continue
            }
            matchDateComponents(date: constructedDate, components: dateComponents, dateString: dateString)
        }
    }
    
    func testCreateDateFromInValidRFC5322StringReturnsNil() {
        let inValidDates = [
            "Sun, 06 Nov 1994 08:49 GMT",
            "06 Nov 1994 08:49:37 GMT",
            "Son, 06 Nov 1994 08:49:37 GMT",
            "Mon, 06 Now 1994 08:49:37 GMT",
            "Mon,06 Nov 1994 08:49:37 GMT",
            "Mon, 32 Nov 1994 08:49:37 GMT",
            "Mon, 07 Nov 1994 14:62:37 GMT",
            "Mon, 07 Nov 1994 14:02:72 GMT"
        ]
        
        let formatter = DateFormatter.rfc5322DateFormatter
        
        for dateString in inValidDates {
            let constructedDate: Date? = formatter.date(from: dateString)
            XCTAssertNil(constructedDate, "able to parse invalid RFC7231 string: \(dateString)")
        }
    }
    
    func testCreateDateFromValidISO8601StringWithoutFractionalSeconds() {
        let validDates = [
            // standard
            "1993-11-20T05:45:01Z":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 5, minute: 45, second: 1),
            "1993-11-20T05:45:01z":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 5, minute: 45, second: 1),
            // with offset
            "1993-11-20T05:45:01+05:00":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 0, minute: 45, second: 1),
            "1993-11-20T05:45:01-05:00":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 10, minute: 45, second: 1),
            "1993-11-20T05:45:01-00:02":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 5, minute: 47, second: 1),
            "1993-11-20T05:45:01-00:00:10":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 5, minute: 45, second: 11),
            "1993-11-20T05:05:01 -0050":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 5, minute: 55, second: 1),
            "1993-11-20T05:50:01 +005001":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 5, minute: 0, second: 0),
            // padding zeroes is handled
            "193-7-022T05:00045:001 +005001":
                ExpectedDateComponents(day: 22, month: 7, year: 193, hour: 4, minute: 55, second: 0)
        ]
        
        let formatter = DateFormatter.iso8601DateFormatterWithoutFractionalSeconds
        
        for (dateString, dateComponents) in validDates {
            guard let constructedDate = formatter.date(from: dateString) else {
                XCTFail("could not parse ISO8601 string: \(dateString)")
                continue
            }
            matchDateComponents(date: constructedDate, components: dateComponents, dateString: dateString)
        }
    }
    
    func testCreateDateFromValidISO8601StringWithFractionalSeconds() {
        // TODO:: why is the precision for nanoSeconds low?
        let validDates = [
            // standard
            "1993-11-20T05:45:01.1Z":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 5, minute: 45, second: 1, nanoSecond: 100000023),
             "1993-11-20T05:45:01.1z":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 5, minute: 45, second: 1, nanoSecond: 100000023),
             "1993-11-20T05:00:00.123456789z":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 5, minute: 0, second: 0, nanoSecond: 123000025),
             "1993-11-20T05:45:01.0-05:00":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 10, minute: 45, second: 1, nanoSecond: 0),
             "1993-11-20T05:45:01.010-00:02":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 5, minute: 47, second: 1, nanoSecond: 9999990),
            "1993-11-20T05:45:01.123456-00:00:10":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 5, minute: 45, second: 11, nanoSecond: 123000025),
            "1993-11-20T05:05:01.1 -0050":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 5, minute: 55, second: 1, nanoSecond: 100000023),
            "1993-11-20T05:50:01.007 +005001":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 5, minute: 0, second: 0, nanoSecond: 6999969)
        ]
        
        let formatter = DateFormatter.iso8601DateFormatterWithFractionalSeconds
        
        for (dateString, dateComponents) in validDates {
            guard let constructedDate = formatter.date(from: dateString) else {
                XCTFail("could not parse ISO8601 string: \(dateString)")
                continue
            }
            matchDateComponents(date: constructedDate, components: dateComponents, dateString: dateString)
        }
    }
    
    func testCreateDateFromInValidISO8601StringReturnsNil() {
        let inValidDates = [
            "1993-11-20",
            "20201105T02:31:22Z",
            "20201105",
            "2017-07-032T03:30:00Z",
            "2017-07-22T03::00Z",
            "2017-07-22T03:0f:00Z",
            "1993-11-20T05:45:01z+05:00"
        ]
        
        let formatterWithoutFractionalSeconds = DateFormatter.iso8601DateFormatterWithoutFractionalSeconds
        let formatterWithFractionalSeconds = DateFormatter.iso8601DateFormatterWithFractionalSeconds
        
        for dateString in inValidDates {
            var constructedDate: Date? = formatterWithoutFractionalSeconds.date(from: dateString)
            XCTAssertNil(constructedDate, "able to parse invalid ISO8601 string: \(dateString)")
            
            constructedDate = formatterWithFractionalSeconds.date(from: dateString)
            XCTAssertNil(constructedDate, "able to parse invalid ISO8601 string: \(dateString)")
        }
    }
        
    struct ExpectedDateComponents {
        let day: Int
        let month: Int
        let year: Int
        let hour: Int
        let minute: Int
        let second: Int
        let nanoSecond: Int?
        
        init(day: Int, month: Int, year: Int, hour: Int, minute: Int, second: Int, nanoSecond: Int? = nil) {
            self.day = day
            self.month = month
            self.year = year
            self.hour = hour
            self.minute = minute
            self.second = second
            self.nanoSecond = nanoSecond
        }
    }
    
    func matchDateComponents(date: Date, components: ExpectedDateComponents, dateString: String) {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(abbreviation: "GMT")! // It is known that GMT exists
        
        XCTAssertEqual(calendar.component(.day, from: date), components.day,
                       "Failed to match day for \(dateString)")
        
        XCTAssertEqual(calendar.component(.month, from: date), components.month,
                       "Failed to match month for \(dateString)")
        
        XCTAssertEqual(calendar.component(.year, from: date), components.year,
                       "Failed to match year for \(dateString)")
        
        XCTAssertEqual(calendar.component(.hour, from: date), components.hour,
                       "Failed to match hour for \(dateString)")
        
        XCTAssertEqual(calendar.component(.minute, from: date), components.minute,
                       "Failed to match minute for \(dateString)")
        
        XCTAssertEqual(calendar.component(.second, from: date), components.second,
                       "Failed to match second for \(dateString)")
        
        if components.nanoSecond != nil {
            XCTAssertEqual(calendar.component(.nanosecond, from: date), components.nanoSecond,
                           "Failed to match nano second for \(dateString)")
        }
    }
}

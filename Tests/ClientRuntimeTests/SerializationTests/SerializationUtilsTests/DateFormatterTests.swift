/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import ClientRuntime

class DateFormatterTests: XCTestCase {

    // MARK: - RFC5322 With Fractional Seconds

    func test_rfc5322WithFractionalSeconds_returnsDateForValidRFC5322String() {
        let validDates = [
            // standard
            "Sun, 20 Nov 1993 05:45:1.000 GMT":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 05, minute: 45, second: 1, milliseconds: 0),
            // different timeZone from default GMT
             "Mon, 20 Nov 1993 05:45:1.001 CST":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 11, minute: 45, second: 1, milliseconds: 1),
             "Tue, 1 Nov 1993 05:45:10.020 GMT":
                ExpectedDateComponents(day: 1, month: 11, year: 1993, hour: 05, minute: 45, second: 10, milliseconds: 20),
             // Different offset specs
             "Tue, 20 Nov 1993 05:45:10.04 +0000":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 05, minute: 45, second: 10, milliseconds: 40),
             "Tue, 20 Nov 1993 05:45:00.4 -0015":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 06, minute: 0, second: 0, milliseconds: 400),
             "Mon, 20 Nov 1993 14:02:02.431 +000":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 14, minute: 2, second: 2, milliseconds: 431),
             // default to GMT for unknown timeZones
             "Tue, 20 Nov 1993 05:45:10.032 UT":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 05, minute: 45, second: 10, milliseconds: 32),
             "Tue, 20 Nov 1993 05:45:10.21349433 Z":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 05, minute: 45, second: 10, milliseconds: 213),
             // components without padding
             "Mon, 20 Nov 193 05:45:10.123 GMT":
                ExpectedDateComponents(day: 20, month: 11, year: 193, hour: 05, minute: 45, second: 10, milliseconds: 123),
             "Mon, 20 Nov 1993 4:2:7.1 GMT":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 4, minute: 2, second: 7, milliseconds: 100)
        ]

        let formatter = DateFormatter.rfc5322WithFractionalSeconds

        for (dateString, dateComponents) in validDates {
            guard let constructedDate = formatter.date(from: dateString) else {
                XCTFail("could not parse RFC5322 string: \(dateString)")
                continue
            }
            assert(date: constructedDate, hasComponents: dateComponents, dateString: dateString)
        }
    }

    func test_rfc5322WithFractionalSeconds_returnsNilForInvalidRFC5322String() {
        let inValidDates = [
            "Sun, 06 Nov 1994 08:49.000 GMT",
            "06 Nov 1994 08:49:37.000 GMT",
            "Son, 06 Nov 1994 08:49:37.000 GMT",
            "Mon, 06 Now 1994 08:49:37.000 GMT",
            "Mon,06 Nov 1994 08:49:37.000 GMT",
            "Mon, 32 Nov 1994 08:49:37.000 GMT",
            "Mon, 07 Nov 1994 14:62:37.000 GMT",
            "Mon, 07 Nov 1994 14:02:72.000 GMT",

            // standard rfc5322 string but should fail since it excludes fractional seconds
            "Sun, 20 Nov 1993 05:45:1 GMT"
        ]

        let formatter = DateFormatter.rfc5322WithFractionalSeconds

        for dateString in inValidDates {
            let constructedDate: Date? = formatter.date(from: dateString)
            XCTAssertNil(constructedDate, "able to parse invalid RFC7231 string: \(dateString)")
        }
    }

    func test_rfc5322WithFractionalSeconds_returnsStringInRFC5322Format() {
        let date = Date.makeDateForTests(day: 04, month: 05, year: 1991, hour: 10, minute: 12, second: 10, milliseconds: 123)
        let dateString = date.rfc5322WithFractionalSeconds()
        XCTAssertEqual(dateString, "Sat, 04 May 1991 10:12:10.123 GMT")
    }

    // MARK: - RFC5322 Without Fractional Seconds

    func test_rfc5322WithoutFractionalSeconds_returnsDateForValidRFC5322String() {
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

        let formatter = DateFormatter.rfc5322WithoutFractionalSeconds

        for (dateString, dateComponents) in validDates {
            guard let constructedDate = formatter.date(from: dateString) else {
                XCTFail("could not parse RFC5322 string: \(dateString)")
                continue
            }
            assert(date: constructedDate, hasComponents: dateComponents, dateString: dateString)
        }
    }

    func test_rfc5322WithoutFractionalSeconds_returnsNilForInvalidRFC5322String() {
        let inValidDates = [
            "Sun, 06 Nov 1994 08:49 GMT",
            "06 Nov 1994 08:49:37 GMT",
            "Son, 06 Nov 1994 08:49:37 GMT",
            "Mon, 06 Now 1994 08:49:37 GMT",
            "Mon,06 Nov 1994 08:49:37 GMT",
            "Mon, 32 Nov 1994 08:49:37 GMT",
            "Mon, 07 Nov 1994 14:62:37 GMT",
            "Mon, 07 Nov 1994 14:02:72 GMT",

            // standard rfc5322 string but should fail since it includes fractional seconds
            "Sun, 20 Nov 1993 05:45:1.000 GMT"
        ]

        let formatter = DateFormatter.rfc5322WithoutFractionalSeconds

        for dateString in inValidDates {
            let constructedDate: Date? = formatter.date(from: dateString)
            XCTAssertNil(constructedDate, "able to parse invalid RFC7231 string: \(dateString)")
        }
    }

    func test_rfc5322WithoutFractionalSeconds_returnsStringInRFC5322Format() {
        let date = Date.makeDateForTests(day: 04, month: 05, year: 1991, hour: 10, minute: 12, second: 10)
        let dateString = date.rfc5322WithoutFractionalSeconds()
        XCTAssertEqual(dateString, "Sat, 04 May 1991 10:12:10 GMT")
    }

    // MARK: - ISO8601 With Fractional Seconds

    func test_iso8601WithFractionalSeconds_returnsDateForValidISO8601String() {
        let validDates = [
            // standard
            "1993-11-20T05:45:01.1Z":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 5, minute: 45, second: 1, milliseconds: 100),
             "1993-11-20T05:45:01.1z":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 5, minute: 45, second: 1, milliseconds: 100),
             "1993-11-20T05:00:00.123456789z":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 5, minute: 0, second: 0, milliseconds: 123),
             "1993-11-20T05:45:01.0-05:00":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 10, minute: 45, second: 1, milliseconds: 0),
             "1993-11-20T05:45:01.010-00:02":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 5, minute: 47, second: 1, milliseconds: 10),
            "1993-11-20T05:45:01.123456-00:00:10":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 5, minute: 45, second: 11, milliseconds: 123),
            "1993-11-20T05:05:01.1 -0050":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 5, minute: 55, second: 1, milliseconds: 100),
            "1993-11-20T05:50:01.007 +005001":
                ExpectedDateComponents(day: 20, month: 11, year: 1993, hour: 5, minute: 0, second: 0, milliseconds: 7)
        ]

        let formatter = DateFormatter.iso8601DateFormatterWithFractionalSeconds

        for (dateString, dateComponents) in validDates {
            guard let constructedDate = formatter.date(from: dateString) else {
                XCTFail("could not parse ISO8601 string: \(dateString)")
                continue
            }
            assert(date: constructedDate, hasComponents: dateComponents, dateString: dateString)
        }
    }

    func test_iso8601WithFractionalSeconds_returnsNilForInvalidISO8601String() {
        let inValidDates = [
            "1993-11-20",
            "20201105T02:31:22Z",
            "20201105",
            "2017-07-032T03:30:00Z",
            "2017-07-22T03::00Z",
            "2017-07-22T03:0f:00Z",
            "1993-11-20T05:45:01z+05:00",

            // standard rfc5322 string but should fail since it excludes fractional seconds
            "1993-11-20T05:45:01Z"
        ]

        let formatter = DateFormatter.iso8601DateFormatterWithFractionalSeconds

        for dateString in inValidDates {
            let constructedDate: Date? = formatter.date(from: dateString)
            XCTAssertNil(constructedDate, "able to parse invalid ISO8601 string: \(dateString)")
        }
    }

    func test_iso8601WithFractionalSeconds_returnsStringInISO8601Format() {
        let date = Date.makeDateForTests(day: 04, month: 05, year: 1991, hour: 10, minute: 12, second: 10, milliseconds: 123)
        let dateString = date.iso8601WithFractionalSeconds()
        XCTAssertEqual(dateString, "1991-05-04T10:12:10.123Z")
    }

    // MARK: - ISO8601 Without Fractional Seconds

    func test_iso8601WithoutFractionalSeconds_returnsDateForValidISO8601String() {
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
            assert(date: constructedDate, hasComponents: dateComponents, dateString: dateString)
        }
    }

    func test_iso8601WithoutFractionalSeconds_returnsNilForInvalidISO8601String() {
        let inValidDates = [
            "1993-11-20",
            "20201105T02:31:22Z",
            "20201105",
            "2017-07-032T03:30:00Z",
            "2017-07-22T03::00Z",
            "2017-07-22T03:0f:00Z",
            "1993-11-20T05:45:01z+05:00",

            // standard rfc5322 string but should fail since it includes fractional seconds
            "1993-11-20T05:45:01.000Z"
        ]

        let formatter = DateFormatter.iso8601DateFormatterWithoutFractionalSeconds

        for dateString in inValidDates {
            let constructedDate: Date? = formatter.date(from: dateString)
            XCTAssertNil(constructedDate, "able to parse invalid ISO8601 string: \(dateString)")
        }
    }

    func test_iso8601WithoutFractionalSeconds_returnsStringInISO8601Format() {
        let date = Date.makeDateForTests(day: 04, month: 05, year: 1991, hour: 10, minute: 12, second: 10)
        let dateString = date.iso8601WithoutFractionalSeconds()
        XCTAssertEqual(dateString, "1991-05-04T10:12:10Z")
    }

    // MARK: - Test Helpers

    struct ExpectedDateComponents {
        let day: Int
        let month: Int
        let year: Int
        let hour: Int
        let minute: Int
        let second: Int
        let milliseconds: Int?

        init(day: Int, month: Int, year: Int, hour: Int, minute: Int, second: Int, milliseconds: Int? = nil) {
            self.day = day
            self.month = month
            self.year = year
            self.hour = hour
            self.minute = minute
            self.second = second
            self.milliseconds = milliseconds
        }
    }

    func assert(
        date: Date,
        hasComponents
        components: ExpectedDateComponents,
        dateString: String,
        line: UInt = #line
    ) {
        var calendar = Calendar.current
        calendar.timeZone = TimeZone(abbreviation: "GMT")! // It is known that GMT exists

        XCTAssertEqual(
            calendar.component(.day, from: date),
            components.day,
            "Failed to match day for \(dateString)",
            line: line
        )

        XCTAssertEqual(
            calendar.component(.month, from: date),
            components.month,
            "Failed to match month for \(dateString)",
            line: line
        )

        XCTAssertEqual(
            calendar.component(.year, from: date),
            components.year,
            "Failed to match year for \(dateString)",
            line: line
        )

        XCTAssertEqual(
            calendar.component(.hour, from: date),
            components.hour,
            "Failed to match hour for \(dateString)",
            line: line
        )

        XCTAssertEqual(
            calendar.component(.minute, from: date),
            components.minute,
            "Failed to match minute for \(dateString)",
            line: line
        )

        XCTAssertEqual(
            calendar.component(.second, from: date),
            components.second,
            "Failed to match second for \(dateString)",
            line: line
        )

        if components.milliseconds != nil {
            // The date formatters only support up-to milliseconds, so comparing nanoseconds is confusing
            // because the nanoseconds value will be rounded to only include milliseconds and the value itself
            // will be something unusual due to floating point representation (such as .007 will render as 6999969).
            // So let's extract the milliseconds from the nanoseconds value to make the tests easier to read and more faithful
            // to the intended behavior.
            let nanoseconds = calendar.component(.nanosecond, from: date)
            let milliseconds = Int((Double(nanoseconds) / 1_000_000).rounded())
            XCTAssertEqual(
                milliseconds,
                components.milliseconds,
                "Failed to match nano second for \(dateString)",
                line: line
            )
        }
    }
}

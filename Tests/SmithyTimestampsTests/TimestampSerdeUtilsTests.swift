//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import SmithyTimestamps

class TimestampSerdeUtilsTests: XCTestCase {

    let testDateWithFractionalSeconds =  Date.makeDateForTests(
        day: 04,
        month: 05,
        year: 1991,
        hour: 10,
        minute: 12,
        second: 10,
        milliseconds: 123
    )

    let testDateWithoutFractionalSeconds =  Date.makeDateForTests(
        day: 04,
        month: 05,
        year: 1991,
        hour: 10,
        minute: 12,
        second: 10
    )

    // MARK: - Encoding Tests

    // Precision difference in linux documented in https://github.com/awslabs/aws-sdk-swift/issues/1006
    func test_TimestampFormatter_encodeEpochSecondsDateWithFractionalSeconds() throws {
        let formatter = TimestampFormatter(format: .epochSeconds)
        let timestamp = formatter.string(from: testDateWithFractionalSeconds)
        let timestampAsDouble = try XCTUnwrap(TimeInterval(timestamp))
        XCTAssertEqual(timestampAsDouble, 673351930.12300003, accuracy: 0.001)
    }

    func test_TimestampFormatter_encodeEpochSecondsDateWithoutFractionalSeconds() throws {
        let formatter = TimestampFormatter(format: .epochSeconds)
        let timestamp = formatter.string(from: testDateWithoutFractionalSeconds)
        let timestampAsInt = try XCTUnwrap(Int(timestamp))
        XCTAssertEqual(timestampAsInt, 673351930)
    }

    func test_TimestampFormatter_encodeDateTimeWithFractionalSeconds() throws {
        let formatter = TimestampFormatter(format: .dateTime)
        let timestamp = formatter.string(from: testDateWithFractionalSeconds)
        XCTAssertEqual(timestamp, "1991-05-04T10:12:10.123Z")
    }

    func test_TimestampFormatter_encodeDateTimeWithoutFractionalSeconds() throws {
        let formatter = TimestampFormatter(format: .dateTime)
        let timestamp = formatter.string(from: testDateWithoutFractionalSeconds)
        XCTAssertEqual(timestamp, "1991-05-04T10:12:10Z")
    }

    func test_TimestampFormatter_encodeHttpDateWithFractionalSeconds() throws {
        let formatter = TimestampFormatter(format: .httpDate)
        let timestamp = formatter.string(from: testDateWithFractionalSeconds)
        XCTAssertEqual(timestamp, "Sat, 04 May 1991 10:12:10.123 GMT")
    }

    func test_TimestampFormatter_encodeHttpDateWithoutFractionalSeconds() throws {
        let formatter = TimestampFormatter(format: .httpDate)
        let timestamp = formatter.string(from: testDateWithoutFractionalSeconds)
        XCTAssertEqual(timestamp, "Sat, 04 May 1991 10:12:10 GMT")
    }


    // MARK: - Decoding Tests

    func test_TimestampFormatter_decodesExpectedValue() throws {
        let subjects: [(TimestampFormat, String, Date?)] = [
            (.epochSeconds, "\(testDateWithFractionalSeconds.timeIntervalSince1970)", testDateWithFractionalSeconds),
            (.epochSeconds, "\(testDateWithoutFractionalSeconds.timeIntervalSince1970)", testDateWithoutFractionalSeconds),
            (.epochSeconds, "", nil),
            (.dateTime, "1991-05-04T10:12:10.123Z", testDateWithFractionalSeconds),
            (.dateTime, "1991-05-04T10:12:10Z", testDateWithoutFractionalSeconds),
            (.dateTime, "", nil),
            (.httpDate, "Sat, 04 May 1991 10:12:10.123 GMT", testDateWithFractionalSeconds),
            (.httpDate, "Sat, 04 May 1991 10:12:10 GMT", testDateWithoutFractionalSeconds),
            (.httpDate, "", nil)
        ]

        for (format, timestamp, expectedValue) in subjects {
            let formatter = TimestampFormatter(format: format)
            let date = formatter.date(from: timestamp)
            XCTAssertEqual(date, expectedValue)
        }
    }
}

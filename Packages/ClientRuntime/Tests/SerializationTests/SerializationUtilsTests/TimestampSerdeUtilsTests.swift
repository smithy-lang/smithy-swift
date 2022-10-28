//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import ClientRuntime

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
    
    // MARK: - TimestampFormat.encodingValueForDate Tests
    
    func test_encodingValueForDate_forEpochSeconds_returnsTimeInterval() throws {
        let date = Date(timeIntervalSince1970: 12345678)
        let result = TimestampFormat.epochSeconds.encodingValueForDate(date) as? TimeInterval
        let seconds = try XCTUnwrap(result, "encodingValueForDate returned invalid type for epochSeconds format")
        XCTAssertEqual(seconds, 12345678)
    }
    
    func test_encodingValueForDate_forDateTime_returnsISO8601StringWithFractionalSeconds() throws {
        let result = TimestampFormat.dateTime.encodingValueForDate(testDateWithFractionalSeconds) as? String
        let dateString = try XCTUnwrap(result, "encodingValueForDate returned invalid type for dateTime format")
        XCTAssertEqual(dateString, "1991-05-04T10:12:10.123Z")
    }
    
    func test_encodingValueForDate_forHttpDate_returnsRFC5322StringWithFractionalSeconds() throws {
        let result = TimestampFormat.httpDate.encodingValueForDate(testDateWithFractionalSeconds) as? String
        let dateString = try XCTUnwrap(result, "encodingValueForDate returned invalid type for httpDate format")
        XCTAssertEqual(dateString, "Sat, 04 May 1991 10:12:10.123 GMT")
    }
    
    // MARK: - Encoding Tests
    
    func test_encodeTimeStamp_forKeyedContainer_returnsExpectedValue() throws {
        let encoder = JSONEncoder()
        
        struct Container: Encodable {
            let timestamp: Date
            enum CodingKeys: String, CodingKey {
                case timestamp
            }
            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encodeTimestamp(
                    timestamp,
                    format: .dateTime,
                    forKey: .timestamp
                )
            }
        }
        let container = Container(timestamp: testDateWithFractionalSeconds)
        let data = try encoder.encode(container)
        let dataAsString = String.init(data: data, encoding: .utf8)!
        XCTAssertEqual(dataAsString, "{\"timestamp\":\"1991-05-04T10:12:10.123Z\"}")
    }
    
    func test_encodeTimeStamp_forSingleValueContainer_returnsExpectedValue() throws {
        let encoder = JSONEncoder()
        
        struct Container: Encodable {
            let timestamp: Date
            func encode(to encoder: Encoder) throws {
                var container = encoder.singleValueContainer()
                try container.encodeTimestamp(timestamp, format: .dateTime)
            }
        }
        let container = Container(timestamp: testDateWithFractionalSeconds)
        let data = try encoder.encode(container)
        let dataAsString = String.init(data: data, encoding: .utf8)!
        XCTAssertEqual(dataAsString, "\"1991-05-04T10:12:10.123Z\"")
    }
    
    // MARK: - Decoding Tests
    
    func test_decodeTimestamp_returnsExpectedValue() throws {
        struct Container: Decodable {
            let timestamp: Date
            static var format: TimestampFormat = .dateTime
            enum CodingKeys: String, CodingKey {
                case timestamp
            }
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.timestamp = try container.decodeTimestamp(Self.format, forKey: .timestamp)
            }
        }
        
        let subjects: [(TimestampFormat, String, Date)] = [
            (.epochSeconds, "{\"timestamp\":\(testDateWithFractionalSeconds.timeIntervalSince1970)}", testDateWithFractionalSeconds),
            (.epochSeconds, "{\"timestamp\":\(testDateWithoutFractionalSeconds.timeIntervalSince1970)}", testDateWithoutFractionalSeconds),
            (.dateTime, "{\"timestamp\":\"1991-05-04T10:12:10.123Z\"}", testDateWithFractionalSeconds),
            (.dateTime, "{\"timestamp\":\"1991-05-04T10:12:10Z\"}", testDateWithoutFractionalSeconds),
            (.httpDate, "{\"timestamp\":\"Sat, 04 May 1991 10:12:10.123 GMT\"}", testDateWithFractionalSeconds),
            (.httpDate, "{\"timestamp\":\"Sat, 04 May 1991 10:12:10 GMT\"}", testDateWithoutFractionalSeconds)
        ]
        
        let decoder = JSONDecoder()
        
        for (format, json, expectedValue) in subjects {
            Container.format = format
            let data = json.data(using: .utf8)!
            let container = try decoder.decode(Container.self, from: data)
            XCTAssertEqual(container.timestamp, expectedValue)
        }
    }
    
    func test_decodeTimestampIfPresent_returnsExpectedValue() throws {
        struct Container: Decodable {
            let timestamp: Date?
            static var format: TimestampFormat = .dateTime
            enum CodingKeys: String, CodingKey {
                case timestamp
            }
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.timestamp = try container.decodeTimestampIfPresent(Self.format, forKey: .timestamp)
            }
        }
        
        let subjects: [(TimestampFormat, String, Date?)] = [
            (.epochSeconds, "{\"timestamp\":\(testDateWithFractionalSeconds.timeIntervalSince1970)}", testDateWithFractionalSeconds),
            (.epochSeconds, "{\"timestamp\":\(testDateWithoutFractionalSeconds.timeIntervalSince1970)}", testDateWithoutFractionalSeconds),
            (.epochSeconds, "{}", nil),
            (.dateTime, "{\"timestamp\":\"1991-05-04T10:12:10.123Z\"}", testDateWithFractionalSeconds),
            (.dateTime, "{\"timestamp\":\"1991-05-04T10:12:10Z\"}", testDateWithoutFractionalSeconds),
            (.dateTime, "{}", nil),
            (.httpDate, "{\"timestamp\":\"Sat, 04 May 1991 10:12:10.123 GMT\"}", testDateWithFractionalSeconds),
            (.httpDate, "{\"timestamp\":\"Sat, 04 May 1991 10:12:10 GMT\"}", testDateWithoutFractionalSeconds),
            (.httpDate, "{}", nil)
        ]
        
        let decoder = JSONDecoder()
        
        for (format, json, expectedValue) in subjects {
            Container.format = format
            let data = json.data(using: .utf8)!
            let container = try decoder.decode(Container.self, from: data)
            XCTAssertEqual(container.timestamp, expectedValue)
        }
    }
}

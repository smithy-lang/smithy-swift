//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
import AWSJSONTestSDK
@_spi(SchemaBasedSerde)
import SmithyJSON
@_spi(SmithyTimestamps)
import SmithyTimestamps
import XCTest

final class DeserializerTests: XCTestCase {

    func test_httpDate_itDeserializesHTTPDate() throws {
        let httpDateTimestamp = "Thu, 09 Jul 2026 17:24:18.769 GMT"
        let expected = TimestampFormatter(format: .httpDate).date(from: httpDateTimestamp)
        let data = Data("{\"httpDateTimestamp\":\"\(httpDateTimestamp)\"}".utf8)

        let subject = try Deserializer(usesJSONNameTrait: false, data: data)
        let actual = try SerdeOperationOutput.deserialize(subject)

        XCTAssertEqual(actual.httpDateTimestamp, expected)
    }

    func test_dateTime_itDeserializesDateTime() throws {
        let dateTimeTimestamp = "2026-07-09T17:28:41.990Z"
        let expected = TimestampFormatter(format: .dateTime).date(from: dateTimeTimestamp)
        let data = Data("{\"dateTimeTimestamp\":\"\(dateTimeTimestamp)\"}".utf8)

        let subject = try Deserializer(usesJSONNameTrait: false, data: data)
        let actual = try SerdeOperationOutput.deserialize(subject)

        XCTAssertEqual(actual.dateTimeTimestamp, expected)
    }

    func test_requiredTimestamps_itDeserializesRequiredTimestampsOfEveryFormat() throws {
        let json = """
        {"requiredTimestamps":{\
        "dateTime":"2025-07-10T01:14:19Z",\
        "httpDate":"Thu, 10 Jul 2025 01:14:19 GMT",\
        "epochSeconds":1752110059\
        }}
        """
        let expected = Date(timeIntervalSince1970: 1752110059)

        let subject = try Deserializer(usesJSONNameTrait: false, data: Data(json.utf8))
        let actual = try SerdeOperationOutput.deserialize(subject)

        XCTAssertEqual(actual.requiredTimestamps?.dateTime, expected)
        XCTAssertEqual(actual.requiredTimestamps?.httpDate, expected)
        XCTAssertEqual(actual.requiredTimestamps?.epochSeconds, expected)
    }

    func test_requiredTimestamps_itDefaultsOmittedRequiredTimestampsToEpochZero() throws {
        let data = Data("{\"requiredTimestamps\":{}}".utf8)
        let expected = Date(timeIntervalSince1970: 0)

        let subject = try Deserializer(usesJSONNameTrait: false, data: data)
        let actual = try SerdeOperationOutput.deserialize(subject)

        XCTAssertEqual(actual.requiredTimestamps?.dateTime, expected)
        XCTAssertEqual(actual.requiredTimestamps?.httpDate, expected)
        XCTAssertEqual(actual.requiredTimestamps?.epochSeconds, expected)
    }

    func test_requiredEnums_itDeserializesRequiredEnums() throws {
        let data = Data("{\"requiredEnums\":{\"enum\":\"a\",\"intEnum\":1}}".utf8)

        let subject = try Deserializer(usesJSONNameTrait: false, data: data)
        let actual = try SerdeOperationOutput.deserialize(subject)

        XCTAssertEqual(actual.requiredEnums?.`enum`, .a)
        XCTAssertEqual(actual.requiredEnums?.intEnum, .one)
    }

    func test_requiredEnums_itDefaultsOmittedRequiredEnumsToUnknown() throws {
        let data = Data("{\"requiredEnums\":{}}".utf8)

        let subject = try Deserializer(usesJSONNameTrait: false, data: data)
        let actual = try SerdeOperationOutput.deserialize(subject)

        XCTAssertEqual(actual.requiredEnums?.`enum`, .sdkUnknown(""))
        XCTAssertEqual(actual.requiredEnums?.intEnum, .sdkUnknown(0))
    }

    func test_epochSeconds_itDeserializesEpochSeconds() throws {
        let epochSecondsTimestamp = 1783618892.951
        let expected = TimestampFormatter(format: .epochSeconds).date(from: "\(epochSecondsTimestamp)")
        let data = Data("{\"epochSecondsTimestamp\":\(epochSecondsTimestamp)}".utf8)

        let subject = try Deserializer(usesJSONNameTrait: false, data: data)
        let actual = try SerdeOperationOutput.deserialize(subject)

        XCTAssertEqual(actual.epochSecondsTimestamp, expected)
    }
}

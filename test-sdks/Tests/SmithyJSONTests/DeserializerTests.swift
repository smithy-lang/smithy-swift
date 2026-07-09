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

final class DeserializeTests: XCTestCase {

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

    func test_epochSeconds_itDeserializesEpochSeconds() throws {
        print(Date().timeIntervalSince1970)
        let epochSecondsTimestamp = 1783618892.951
        let expected = TimestampFormatter(format: .epochSeconds).date(from: "\(epochSecondsTimestamp)")
        let data = Data("{\"epochSecondsTimestamp\":\(epochSecondsTimestamp)}".utf8)

        let subject = try Deserializer(usesJSONNameTrait: false, data: data)
        let actual = try SerdeOperationOutput.deserialize(subject)

        XCTAssertEqual(actual.epochSecondsTimestamp, expected)
    }
}

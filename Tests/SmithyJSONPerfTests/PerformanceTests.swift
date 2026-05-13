//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(SchemaBasedSerde) import SmithySerialization
@_spi(SchemaBasedSerde) import AWSJSONTestSDK
@_spi(SchemaBasedSerde) import SmithyJSON

class PerformanceTests: XCTestCase {
    let listLength = 10000
    let reps = 1000
    let deserFactory = {
        try NewDeserializer(data: $0)
//        try Deserializer(data: $0)
    }

    func test_performanceIntegerList() throws {
        let integerList = (1...listLength).map { _ in Int.random(in: Int.min...Int.max) }
        let jsonObject = ["integerList": integerList]
        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject)

        for _ in 1...reps {
            let deser = try deserFactory(jsonData)
            let output = try GetWidgetOutput.deserialize(deser)
//            XCTAssertEqual(output.integerList, integerList)
        }
    }

    func test_performanceBooleanList() throws {
        let booleanList = (1...listLength).map { _ in Bool.random() }
        let jsonObject = ["booleanList": booleanList]
        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject)

        for _ in 1...reps {
            let deser = try deserFactory(jsonData)
            let output = try GetWidgetOutput.deserialize(deser)
            XCTAssertEqual(output.booleanList, booleanList)
        }
    }

    func test_performanceStringList() throws {
        let stringList = (1...listLength).map { _ in UUID().uuidString }
        let jsonObject = ["stringList": stringList]
        let jsonData = try JSONSerialization.data(withJSONObject: jsonObject)

        for _ in 1...reps {
            let deser = try deserFactory(jsonData)
            let output = try GetWidgetOutput.deserialize(deser)
//            XCTAssertEqual(output.stringList, stringList)
        }
    }
}

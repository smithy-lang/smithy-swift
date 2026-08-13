//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(SchemaBasedSerde)
import SmithyHTTPAPI
@_spi(SchemaBasedSerde)
import HTTPBindingsTestSDK

final class HTTPBindingsSerializerTests: XCTestCase {

    func test_allUnboundMembers_allGetSerializedToBody() throws {
        let operation = HTTPBindingsClient.allUnboundMembersOperation
        let input = AllUnboundMembersInput(a: "xyz", b: 321, c: true)

        let subject = try HTTPBindingsSerializer(codec: TestCodec(), operation: operation)
        try input.serialize(subject)

        XCTAssertEqual(try subject.data, Data(#"{"a":"xyz","b":321,"c":true}"#.utf8))
    }

    func test_allBoundMembers_noneGetSerializedToBody() throws {
        let operation = HTTPBindingsClient.allBoundMembersOperation
        let input = AllBoundMembersInput(a: "xyz", b: 321, c: true)

        let subject = try HTTPBindingsSerializer(codec: TestCodec(), operation: operation)
        try input.serialize(subject)

        XCTAssertEqual(try subject.data, Data(#"{}"#.utf8))
    }
}

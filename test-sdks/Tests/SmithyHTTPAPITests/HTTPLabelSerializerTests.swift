//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@_spi(SchemaBasedSerde)
import Smithy
@_spi(SchemaBasedSerde)
import SmithyHTTPAPI
@_spi(SchemaBasedSerde)
import SmithySerialization
@_spi(SchemaBasedSerde)
@testable import RestJSON1TestSDK

final class HTTPLabelSerializerTests: XCTestCase {

    func test_string_serializesStringIntoURI() throws {
        let operation = RestJSON1TestSDK.RestJSON1ServiceClient.getWidgetOperation
        let uri = try XCTUnwrap(operation.schema.getTrait(HTTPTrait.self)?.uri)
        let subject = HTTPLabelSerializer(uri: uri)

        let input = GetWidgetInput(tidbit: "abcdef")
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.uri, "/abcdef")
    }

    func test_string_serializesStringIntoURIEscapingSpecialCharactersIncludingSlash() throws {
        let operation = RestJSON1TestSDK.RestJSON1ServiceClient.getWidgetOperation
        let uri = try XCTUnwrap(operation.schema.getTrait(HTTPTrait.self)?.uri)
        let subject = HTTPLabelSerializer(uri: uri)

        let input = GetWidgetInput(tidbit: "abc/*=")
        try input.serializeMembers(operation.inputSchema, subject)

        XCTAssertEqual(subject.uri, "/abc%2F%2A%3D")
    }
}

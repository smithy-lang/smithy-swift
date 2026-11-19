//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import struct Foundation.Data
@_spi(SchemaBasedSerde)
import Smithy
@_spi(SchemaBasedSerde)
import SmithyHTTPAPI
@_spi(SchemaBasedSerde)
import SmithySerialization
@_spi(SchemaBasedSerde)
import HTTPBindingsTestSDK

// Tests that `HTTPBindingsDeserializer` deserializes each member of a response structure with the
// deserializer for that member's HTTP binding:
// https://smithy.io/2.0/spec/http-bindings.html
final class HTTPBindingsDeserializerTests: XCTestCase {

    func test_deserializesEveryBoundMemberOfAResponse() throws {
        let response = HTTPResponse(
            headers: Headers(["X-Specific": "Specific", "X-Meta-Abc": "Abc value"]),
            statusCode: .created
        )

        let output = try deserialize(response, body: #"{"body":"abc"}"#)

        XCTAssertEqual(output.specific, "Specific")
        XCTAssertEqual(output.metadata, ["Abc": "Abc value"])
        XCTAssertEqual(output.status, 201)
        XCTAssertEqual(output.body, "abc")
    }

    func test_headerBoundMemberIsNotDisplacedByThePlaceholderForARequiredMember() throws {
        // The header-bound member is `@required` and is not part of the body, so deserializing the
        // body fills it with a placeholder.  The value carried by the header must win over that.
        let response = HTTPResponse(headers: Headers(["X-Specific": "Specific"]), statusCode: .ok)

        let output = try deserialize(response, body: "{}")

        XCTAssertEqual(output.specific, "Specific")
    }

    func test_deserializesBoundMembersOfAResponseWithNoBody() throws {
        // A streaming response is deserialized with no body data; the other bindings still fill.
        let response = HTTPResponse(
            headers: Headers(["X-Specific": "Specific", "X-Meta-Abc": "Abc value"]),
            statusCode: .created
        )

        let output = try deserialize(response, body: nil)

        XCTAssertEqual(output.specific, "Specific")
        XCTAssertEqual(output.metadata, ["Abc": "Abc value"])
        XCTAssertEqual(output.status, 201)
        XCTAssertNil(output.body)
    }

    func test_absentHeadersLeaveTheirMembersUnsetAndTheMetadataMapEmpty() throws {
        let output = try deserialize(HTTPResponse(statusCode: .ok), body: #"{"body":"abc"}"#)

        // The header-bound member is left with the placeholder that deserializing the body fills in
        // for a required member, because there is no header to deserialize over it.
        XCTAssertEqual(output.specific, "")
        // No header matches the prefix, so the map is empty rather than unset.
        XCTAssertEqual(output.metadata, [:])
        XCTAssertEqual(output.status, 200)
        XCTAssertEqual(output.body, "abc")
    }

    func test_absentHeaderLeavesAnOptionalMemberUnset() throws {
        // With no body to fill in a placeholder, a member whose header is absent stays unset.
        let output = try deserialize(HTTPResponse(statusCode: .ok), body: nil)

        XCTAssertNil(output.specific)
        XCTAssertEqual(output.metadata, [:])
        XCTAssertEqual(output.status, 200)
        XCTAssertNil(output.body)
    }

    // MARK: - Private methods

    private func deserialize(
        _ response: HTTPResponse,
        body: String?
    ) throws -> AllBoundResponseMembersOutput {
        let subject = HTTPBindingsDeserializer(
            codec: TestCodec(),
            response: response,
            data: body.map { Data($0.utf8) }
        )
        return try AllBoundResponseMembersOutput.deserialize(subject)
    }
}

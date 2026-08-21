//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import struct ClientRuntime.UnknownHTTPServiceError
import enum SmithyHTTPAPI.HTTPStatusCode
@_spi(SchemaBasedSerde)
import RestJSON1ResponseTestSDK

/// Tests the RestJSON1 client protocol's deserialization of successful response bodies.
final class HTTPClientProtocolResponseTests: XCTestCase, RestJSON1TestBase {

    // MARK: - Response body

    func test_success_deserializesBodyMembers() async throws {
        let output = try await output(
            response(status: .ok, body: #"{"name":"thing","count":7,"items":["a","b"]}"#)
        )

        XCTAssertEqual(output.name, "thing")
        XCTAssertEqual(output.count, 7)
        XCTAssertEqual(output.items, ["a", "b"])
    }

    // The response body from a live HTTP client is a non-seekable stream that can only be read
    // once, so deserialization must not depend on reading the body a second time.
    func test_success_deserializesBodyMembersFromNonSeekableStream() async throws {
        let output = try await output(
            streamedResponse(status: .ok, body: #"{"name":"thing","count":7,"items":["a","b"]}"#)
        )

        XCTAssertEqual(output.name, "thing")
        XCTAssertEqual(output.count, 7)
        XCTAssertEqual(output.items, ["a", "b"])
    }

    func test_success_emptyBodyDeserializesToEmptyOutput() async throws {
        let output = try await output(response(status: .ok, body: ""))

        XCTAssertNil(output.name)
        XCTAssertNil(output.count)
        XCTAssertNil(output.items)
    }

    func test_success_noBodyDeserializesToEmptyOutput() async throws {
        let output = try await output(response(status: .noContent))

        XCTAssertNil(output.name)
        XCTAssertNil(output.count)
        XCTAssertNil(output.items)
    }

    func test_success_unmodeledBodyMembersAreIgnored() async throws {
        let output = try await output(response(status: .ok, body: #"{"name":"thing","nope":true}"#))

        XCTAssertEqual(output.name, "thing")
    }

    func test_success_nonJSONBodyThrows() async {
        let error = await thrownError(response(status: .ok, body: "<html>hello</html>"))

        XCTAssertNotNil(error)
        XCTAssertFalse(error is UnknownHTTPServiceError)
    }

    // MARK: - Status codes

    // Any 2xx status is a success.
    func test_statusCode_2xxIsSuccess() async throws {
        let statuses: [HTTPStatusCode] = [.ok, .created, .accepted, .noContent, .partialContent, .iAmUsed]
        for status in statuses {
            let output = try await output(response(status: status, body: #"{"name":"ok"}"#))
            XCTAssertEqual(output.name, "ok", "status \(status.rawValue) should be a success")
        }
    }

    // A 3xx status is not a success; it is deserialized as an error.  A redirect body is not an
    // operation output, so deserializing it as one would silently produce an empty output.
    func test_statusCode_3xxIsAnError() async {
        let statuses: [HTTPStatusCode] = [.multipleChoices, .movedPermanently, .found, .notModified, .permanentRedirect]
        for status in statuses {
            let error = await thrownError(response(status: status, body: #"{"name":"ok"}"#))
            XCTAssertTrue(
                error is UnknownHTTPServiceError,
                "status \(status.rawValue) should be an unknown error, got \(error as Any)"
            )
        }
    }

    func test_statusCode_4xxAnd5xxAreErrors() async {
        let statuses: [HTTPStatusCode] = [.badRequest, .notFound, .tooManyRequests, .internalServerError, .serviceUnavailable]
        for status in statuses {
            let error = await thrownError(response(status: status, body: #"{"__type":"SimpleError"}"#))
            XCTAssertTrue(error is SimpleError, "status \(status.rawValue) should be a SimpleError, got \(error as Any)")
        }
    }
}

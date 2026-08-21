//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import struct Foundation.Data
import struct Smithy.Attributes
import enum Smithy.ByteStream
import class Smithy.Context
import struct SmithyHTTPAPI.Headers
import class SmithyHTTPAPI.HTTPResponse
import enum SmithyHTTPAPI.HTTPStatusCode
@_spi(SchemaBasedSerde)
import struct SmithyRestJSON1.HTTPClientProtocol
@_spi(SchemaBasedSerde)
import struct SmithySerialization.Operation
import class SmithyStreams.BufferedStream
@_spi(SchemaBasedSerde)
import RestJSON1ResponseTestSDK

/// Shared helpers for exercising the RestJSON1 client protocol's response deserialization.
protocol RestJSON1TestBase {}

extension RestJSON1TestBase {

    var subject: SmithyRestJSON1.HTTPClientProtocol { .init() }

    var operation: Operation<GetThingInput, GetThingOutput> { RestJSON1ResponseClient.getThingOperation }

    /// A response with the passed status, headers, and body, with the body held in memory.
    func response(
        status: HTTPStatusCode,
        headers: [String: String] = [:],
        body: String? = nil
    ) -> HTTPResponse {
        HTTPResponse(
            headers: Headers(headers),
            statusCode: status,
            body: body.map { ByteStream.data(Data($0.utf8)) } ?? .noStream
        )
    }

    /// A response whose body is a non-seekable stream, as it is when delivered by a live HTTP client.
    ///
    /// A stream like this one may only be read once, so a response body must not be read twice
    /// in the course of deserializing a response or an error.
    func streamedResponse(
        status: HTTPStatusCode,
        headers: [String: String] = [:],
        body: String
    ) -> HTTPResponse {
        HTTPResponse(
            headers: Headers(headers),
            statusCode: status,
            body: .stream(BufferedStream(data: Data(body.utf8), isClosed: true))
        )
    }

    /// Deserializes the passed response into the operation's output.
    func output(_ response: HTTPResponse) async throws -> GetThingOutput {
        try await subject.deserializeResponse(
            operation: operation,
            context: Context(attributes: Attributes()),
            response: response
        )
    }

    /// Deserializes the passed response, which is expected to fail, and returns the error thrown.
    func thrownError(
        _ response: HTTPResponse,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async -> Error? {
        do {
            let output = try await output(response)
            XCTFail("Expected an error but got output: \(output)", file: file, line: line)
            return nil
        } catch {
            return error
        }
    }

    /// Deserializes the passed response, which is expected to fail with a modeled error of the
    /// passed type, and returns that error.
    func thrownError<E: Error>(
        _ response: HTTPResponse,
        as type: E.Type,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async -> E? {
        guard let error = await thrownError(response, file: file, line: line) else { return nil }
        guard let typedError = error as? E else {
            XCTFail("Expected \(E.self) but got \(Swift.type(of: error)): \(error)", file: file, line: line)
            return nil
        }
        return typedError
    }
}

/// An async version of `XCTAssertThrowsError`.
func XCTAssertThrowsErrorAsync(
    _ exp: @autoclosure () async throws -> Void,
    _ message: String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ block: (Error) -> Void = { _ in }
) async {
    do {
        try await exp()
        XCTFail("Should have thrown error. \(message)", file: file, line: line)
    } catch {
        block(error)
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import struct Foundation.Data
import struct Smithy.Attributes
import class Smithy.Context
@_spi(SchemaBasedSerde)
import struct SmithyAWSJSON.HTTPClientProtocol
@_spi(SmithyEventStreams)
import struct SmithyEventStreams.DefaultMessageEncoder
import struct SmithyEventStreamsAPI.Header
import struct SmithyEventStreamsAPI.Message
import struct SmithyHTTPAPI.Headers
import class SmithyHTTPAPI.HTTPResponse
@_spi(SchemaBasedSerde)
import struct SmithySerialization.Operation
import class SmithyStreams.BufferedStream
@_spi(SchemaBasedSerde)
import AWSJSONEventStreamTestSDK

/// Tests the awsJson client protocol's handling of the initial-response on an event streaming response.
final class HTTPClientProtocolEventStreamTests: XCTestCase {

    private let subject = SmithyAWSJSON.HTTPClientProtocol(version: .v1_0)

    // MARK: - Output with only an event stream member

    // When the event stream is the output's only member, the output must be returned without waiting
    // for a message, so a bidirectional stream whose server waits for request events cannot deadlock.
    func test_streamOnlyOutput_returnsBeforeAnyMessageIsReceived() async throws {
        let stream = BufferedStream()

        let output = try await withTimeout(closing: stream) {
            try await self.deserialize(AWSJSONEventStreamClient.eventStreamResponseOperation, stream)
        }

        // An initial-response sent afterward is dropped, and the events after it are delivered.
        try stream.write(contentsOf: encode(initialResponse(#"{}"#)))
        try stream.write(contentsOf: encode(scalarsEvent(#"{"stringMember":"first event"}"#)))
        stream.close()
        let events = try await collect(XCTUnwrap(output.events))
        XCTAssertEqual(events.count, 1)
        guard case .scalarsevent(let event) = events.first else {
            return XCTFail("Expected a scalars event, got \(String(describing: events.first))")
        }
        XCTAssertEqual(event.stringMember, "first event")
    }

    // MARK: - Output with members besides the event stream

    func test_outputWithMembers_fillsMembersFromInitialResponse() async throws {
        let stream = BufferedStream()
        try stream.write(contentsOf: encode(initialResponse(#"{"sessionId":"session-1","timeout":30}"#)))
        try stream.write(contentsOf: encode(scalarsEvent(#"{"stringMember":"first event"}"#)))

        let output = try await withTimeout(closing: stream) {
            try await self.deserialize(AWSJSONEventStreamClient.eventStreamInitialResponseOperation, stream)
        }

        XCTAssertEqual(output.sessionId, "session-1")
        XCTAssertEqual(output.timeout, 30)
        stream.close()
        let events = try await collect(XCTUnwrap(output.events))
        XCTAssertEqual(events.count, 1)
        guard case .scalarsevent(let event) = events.first else {
            return XCTFail("Expected a scalars event, got \(String(describing: events.first))")
        }
        XCTAssertEqual(event.stringMember, "first event")
    }

    func test_outputWithMembers_withoutInitialResponse_leavesMembersUnsetAndDeliversEvents() async throws {
        let stream = BufferedStream()
        try stream.write(contentsOf: encode(scalarsEvent(#"{"stringMember":"first event"}"#)))

        let output = try await withTimeout(closing: stream) {
            try await self.deserialize(AWSJSONEventStreamClient.eventStreamInitialResponseOperation, stream)
        }

        XCTAssertNil(output.sessionId)
        XCTAssertNil(output.timeout)
        stream.close()
        let events = try await collect(XCTUnwrap(output.events))
        XCTAssertEqual(events.count, 1)
    }

    // MARK: - Helpers

    private func deserialize<Input, Output>(
        _ operation: Operation<Input, Output>,
        _ stream: BufferedStream
    ) async throws -> Output {
        let response = HTTPResponse(
            headers: Headers(["Content-Type": "application/vnd.amazon.eventstream"]),
            statusCode: .ok,
            body: .stream(stream)
        )
        return try await subject.deserializeResponse(
            operation: operation,
            context: Context(attributes: Attributes()),
            response: response
        )
    }

    /// Runs the operation, failing the test if it does not finish within the timeout.
    ///
    /// On timeout the stream is closed, so that a read suspended on it resumes and the test can end.
    private func withTimeout<T>(
        closing stream: BufferedStream,
        seconds: Double = 5.0,
        _ operation: () async throws -> T
    ) async throws -> T {
        // Returns true if the timeout expired before it was cancelled.
        let timeout = Task { () -> Bool in
            do {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            } catch {
                return false
            }
            stream.close()
            return true
        }
        let result = try await operation()
        timeout.cancel()
        if await timeout.value {
            XCTFail("Deserialization did not finish within \(seconds) seconds")
            throw TimeoutError()
        }
        return result
    }

    private struct TimeoutError: Error {}

    private func collect<E>(_ events: AsyncThrowingStream<E, Error>) async throws -> [E] {
        var collected = [E]()
        for try await event in events {
            collected.append(event)
        }
        return collected
    }

    private func initialResponse(_ json: String) -> Message {
        message(eventType: "initial-response", json: json)
    }

    private func scalarsEvent(_ json: String) -> Message {
        message(eventType: "scalarsEvent", json: json)
    }

    private func message(eventType: String, json: String) -> Message {
        Message(
            headers: [
                Header(name: ":message-type", value: .string("event")),
                Header(name: ":event-type", value: .string(eventType)),
                Header(name: ":content-type", value: .string("application/json")),
            ],
            payload: Data(json.utf8)
        )
    }

    private func encode(_ message: Message) throws -> Data {
        try DefaultMessageEncoder().encode(message: message)
    }
}

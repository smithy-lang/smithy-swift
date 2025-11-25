//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AsyncHTTPClient
import Foundation
import NIO
import SmithyTestUtil
import XCTest
import class SmithyStreams.BufferedStream
import enum Smithy.LogAgentLevel
import protocol Smithy.LogAgent
import enum Smithy.ByteStream
@testable import SmithySwiftNIO

class SwiftNIOHTTPClientStreamBridgeTests: XCTestCase {
    let allocator = ByteBufferAllocator()

    func test_convertResponseBody_streamsAllDataCorrectly() async throws {

        // The maximum size of input streaming data in the tests
        let maxDataSize = 65_536  // 64 kb

        // Create & fill a buffer with random bytes, for use in later test setup
        // Random buffer is reused because creating random data is slow
        // We are responsible for deallocating it
        let randomBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: maxDataSize)
        defer { randomBuffer.deallocate() }

        for i in 0..<maxDataSize {
            randomBuffer[i] = UInt8.random(in: UInt8.min...UInt8.max)
        }

        // Run this test repeatedly to help uncover any problems
        let numberOfRuns = 100

        for run in 1...numberOfRuns {
            // Test with varying data sizes up to the maximum
            let dataSize = min(run * 1000, maxDataSize)

            // Create original test data
            let originalData = Data(bytes: randomBuffer, count: dataSize)

            // Create a mock AsyncHTTPClient response with the test data
            var buffer = allocator.buffer(capacity: originalData.count)
            buffer.writeBytes(originalData)

            let response = AsyncHTTPClient.HTTPClientResponse(
                version: .http1_1,
                status: .ok,
                headers: [:],
                body: .bytes(buffer)
            )

            let resultStream = await SwiftNIOHTTPClientStreamBridge.convertResponseBody(from: response)
            let convertedData = try await readAllData(from: resultStream)

            XCTAssertEqual(convertedData, originalData,
                          "Run \(run) failed (dataSize: \(dataSize))")
        }
    }

    func test_convertRequestBody_withNoStream() async throws {
        let byteStream = ByteStream.noStream

        let result = try await SwiftNIOHTTPClientStreamBridge.convertRequestBody(
            from: byteStream,
            allocator: allocator
        )

        // Convert the body to an async sequence and verify it's empty
        var totalBytes = 0
        for try await buffer in result {
            totalBytes += buffer.readableBytes
        }

        XCTAssertEqual(totalBytes, 0)
    }

    func test_convertRequestBody_withData() async throws {
        let testData = "Hello, World!".data(using: .utf8)!
        let byteStream = ByteStream.data(testData)

        let result = try await SwiftNIOHTTPClientStreamBridge.convertRequestBody(
            from: byteStream,
            allocator: allocator
        )

        var collectedData = Data()
        for try await buffer in result {
            collectedData.append(Data(buffer: buffer))
        }

        XCTAssertEqual(collectedData, testData)
    }

    func test_convertRequestBody_withStream() async throws {
        // Create random test data
        let dataSize = 1000
        let randomBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: dataSize)
        defer { randomBuffer.deallocate() }

        for i in 0..<dataSize {
            randomBuffer[i] = UInt8.random(in: UInt8.min...UInt8.max)
        }

        let testData = Data(bytes: randomBuffer, count: dataSize)
        let bufferedStream = BufferedStream(data: testData, isClosed: true)
        let byteStream = ByteStream.stream(bufferedStream)

        let result = try await SwiftNIOHTTPClientStreamBridge.convertRequestBody(
            from: byteStream,
            allocator: allocator,
            chunkSize: 100 // try a non-default chunk size
        )

        var collectedData = Data()
        for try await buffer in result {
            collectedData.append(Data(buffer: buffer))
        }

        XCTAssertEqual(collectedData, testData)
    }

    private func readAllData(from byteStream: ByteStream) async throws -> Data {
        switch byteStream {
        case .stream(let stream):
            return try await stream.readToEndAsync() ?? Data()
        case .data(let data):
            return data ?? Data()
        case .noStream:
            return Data()
        }
    }
}

private extension Data {
    init(buffer: ByteBuffer) {
        if let bytes = buffer.getBytes(at: buffer.readerIndex, length: buffer.readableBytes) {
            self.init(bytes)
        } else {
            self.init()
        }
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import NIOCore
import XCTest
import enum Smithy.StreamError
@testable import SmithySwiftNIO

final class ByteBufferStreamTests: XCTestCase {
    let allocator = ByteBufferAllocator()

    private func buffer(_ bytes: [UInt8]) -> ByteBuffer {
        var b = allocator.buffer(capacity: bytes.count)
        b.writeBytes(bytes)
        return b
    }

    // MARK: - Basic write/read round-trips

    func test_writeBuffer_thenReadData_roundTrips() throws {
        let stream = ByteBufferStream()
        stream.writeBuffer(buffer([1, 2, 3]))
        stream.writeBuffer(buffer([4, 5]))
        stream.close()

        let first = try stream.read(upToCount: 10)
        XCTAssertEqual(first, Data([1, 2, 3]))   // reads do not span buffers; one chunk at a time
        let second = try stream.read(upToCount: 10)
        XCTAssertEqual(second, Data([4, 5]))
        XCTAssertNil(try stream.read(upToCount: 10)) // closed + drained -> nil
    }

    func test_readToEndAsync_concatenatesAllChunks() async throws {
        let stream = ByteBufferStream()
        stream.writeBuffer(buffer([10, 20]))
        stream.writeBuffer(buffer([30]))
        stream.writeBuffer(buffer([40, 50, 60]))
        stream.close()

        let all = try await stream.readToEndAsync()
        XCTAssertEqual(all, Data([10, 20, 30, 40, 50, 60]))
    }

    func test_writeContentsOf_Data_path() throws {
        let stream = ByteBufferStream()
        try stream.write(contentsOf: Data([7, 8, 9]))
        stream.close()
        XCTAssertEqual(try stream.readToEnd(), Data([7, 8, 9]))
    }

    func test_writeAsync_default_and_override() async throws {
        let stream = ByteBufferStream()
        try await stream.writeAsync(contentsOf: Data([1, 2]))
        try await stream.writeAsync(contentsOf: Data([3, 4]))
        stream.close()
        let all = try await stream.readToEndAsync()
        XCTAssertEqual(all, Data([1, 2, 3, 4]))
    }

    // MARK: - readBufferAsync zero-copy slice

    func test_readBufferAsync_returnsByteBuffer_andSplitsByCount() async throws {
        let stream = ByteBufferStream()
        stream.writeBuffer(buffer([1, 2, 3, 4, 5]))
        stream.close()

        let part1 = try await stream.readBufferAsync(upToCount: 3)
        XCTAssertEqual(part1.map { Array($0.readableBytesView) }, [1, 2, 3])
        let part2 = try await stream.readBufferAsync(upToCount: 3)
        XCTAssertEqual(part2.map { Array($0.readableBytesView) }, [4, 5])
        let end = try await stream.readBufferAsync(upToCount: 3)
        XCTAssertNil(end)
    }

    // MARK: - Suspended reader resumed by a later write

    func test_readBufferAsync_suspendsThenResumesOnWrite() async throws {
        let stream = ByteBufferStream()

        let reader = Task { () -> [UInt8]? in
            let buf = try await stream.readBufferAsync(upToCount: 100)
            return buf.map { Array($0.readableBytesView) }
        }

        // Give the reader a moment to suspend, then write.
        try await Task.sleep(nanoseconds: 50_000_000)
        stream.writeBuffer(buffer([42, 43]))

        let result = try await reader.value
        XCTAssertEqual(result, [42, 43])
        stream.close()
    }

    // MARK: - Close semantics

    func test_writeAfterClose_throws() throws {
        let stream = ByteBufferStream()
        stream.close()
        XCTAssertThrowsError(try stream.write(contentsOf: Data([1]))) { error in
            guard case StreamError.writeToClosedStream = error else {
                return XCTFail("expected writeToClosedStream, got \(error)")
            }
        }
    }

    func test_lengthKnownOnlyAfterClose() {
        let stream = ByteBufferStream()
        stream.writeBuffer(buffer([1, 2, 3]))
        XCTAssertNil(stream.length)       // unknown while open
        stream.close()
        XCTAssertEqual(stream.length, 3)  // total written, known once closed
    }

    func test_closeWithError_isThrownToReader() async throws {
        struct Boom: Error {}
        let stream = ByteBufferStream()

        let reader = Task { () -> Error? in
            do {
                _ = try await stream.readBufferAsync(upToCount: 10)
                return nil
            } catch {
                return error
            }
        }

        try await Task.sleep(nanoseconds: 50_000_000)
        stream.closeWithError(Boom())

        let err = await reader.value
        XCTAssertTrue(err is Boom)
    }

    // MARK: - Backpressure

    func test_writeBufferAsync_suspendsAtHighWaterMark_resumesOnDrain() async throws {
        // HWM=8 (low-water mark=4). The first write (4 bytes) is below the HWM and returns
        // immediately; the second write pushes buffered bytes to 9 (>= HWM) and parks the
        // producer until a reader drains the buffer below the low-water mark.
        let stream = ByteBufferStream(highWaterMark: 8)

        try await stream.writeBufferAsync(buffer([1, 2, 3, 4]))  // below HWM -> returns

        let writeTask = Task { try await stream.writeBufferAsync(buffer([5, 6, 7, 8, 9])) }

        // The second write should still be suspended shortly after (buffer is full).
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertFalse(writeTask.isCancelled)

        // Drain everything; this brings buffered bytes below the low-water mark and resumes the writer.
        var drained: [UInt8] = []
        while drained.count < 9 {
            guard let buf = try await stream.readBufferAsync(upToCount: 64) else { break }
            drained.append(contentsOf: buf.readableBytesView)
        }
        _ = try await writeTask.value  // must not hang

        XCTAssertEqual(drained, [1, 2, 3, 4, 5, 6, 7, 8, 9])
        stream.close()
    }

    func test_multipleWriters_allResumeAfterDrain() async throws {
        // Regression: write-path drains must wake parked writers, not just reader-path drains.
        // Three concurrent writers contend against a small buffer; draining must resume all
        // of them without hanging.
        let stream = ByteBufferStream(highWaterMark: 8)

        let w1 = Task { try await stream.writeBufferAsync(self.buffer([10, 11, 12, 13, 14])) }
        let w2 = Task { try await stream.writeBufferAsync(self.buffer([20, 21, 22, 23, 24])) }
        let w3 = Task { try await stream.writeBufferAsync(self.buffer([30, 31, 32, 33, 34])) }

        try await Task.sleep(nanoseconds: 80_000_000)  // let writers contend / park

        var got = 0
        while got < 15 {
            guard let buf = try await stream.readBufferAsync(upToCount: 64) else { break }
            got += buf.readableBytes
        }
        _ = try await w1.value
        _ = try await w2.value
        _ = try await w3.value  // must not hang

        XCTAssertEqual(got, 15)
        stream.close()
    }

    // MARK: - Larger fidelity check vs BufferedStream behavior

    func test_manyChunks_preserveOrderAndBytes() async throws {
        let stream = ByteBufferStream()
        var expected = [UInt8]()
        for i in 0..<500 {
            let chunk = (0..<37).map { UInt8((i + $0) & 0xFF) }
            expected.append(contentsOf: chunk)
            stream.writeBuffer(buffer(chunk))
        }
        stream.close()

        let all = try await stream.readToEndAsync()
        XCTAssertEqual(all.map(Array.init), expected)
        XCTAssertEqual(stream.position, expected.count)
        XCTAssertEqual(stream.length, expected.count)
    }
}

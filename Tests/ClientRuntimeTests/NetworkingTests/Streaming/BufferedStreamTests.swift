//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import ClientRuntime

final class BufferedStreamTests: XCTestCase {

    let testData = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A])
    let additionalData = Data([0x0B, 0x0C, 0x0D, 0x0E])

    // MARK: - isSeekable

    func test_isSeekable_isNeverSeekable() {
        let subject = BufferedStream()
        XCTAssertFalse(subject.isSeekable)
    }

    // MARK: - isEmpty

    func test_isEmpty_isTrueWhenCreatedWithoutData() {
        let subject = BufferedStream()
        XCTAssertTrue(subject.isEmpty)
    }

    // MARK: - read(upToCount:)

    func test_read_readsBytesFromBufferInSequence() throws {
        let subject = BufferedStream(data: testData)

        // read up to 4 bytes
        let readData1 = try subject.read(upToCount: 4)
        XCTAssertEqual(readData1, Data([0x00, 0x01, 0x02, 0x03]))
        XCTAssertEqual(4, subject.position)

        // read another 4 bytes
        let readData2 = try subject.read(upToCount: 4)
        XCTAssertEqual(readData2, Data([0x04, 0x05, 0x06, 0x07]))
        XCTAssertEqual(8, subject.position)

        // read another 2 bytes
        let readData3 = try subject.read(upToCount: 2)
        XCTAssertEqual(readData3, Data([0x08, 0x09]))
        XCTAssertEqual(10, subject.position)

        // read another 4 bytes, but only 1 byte is available
        let readData4 = try subject.read(upToCount: 4)
        XCTAssertEqual(readData4, Data([0x0A]))
        XCTAssertEqual(11, subject.position)
    }

    func test_read_readsEmptyDataWhenNoDataRemainsToRead() throws {
        let subject = BufferedStream(data: testData)
        let _ = try subject.read(upToCount: Int.max)
        let readData = try subject.read(upToCount: Int.max)
        XCTAssertEqual(Data(), readData)
    }

    func test_read_readsRemainingDataThenNilWhenStreamIsClosed() throws {
        let subject = BufferedStream(data: testData)
        subject.close()
        let readData1 = try subject.read(upToCount: Int.max)
        XCTAssertEqual(testData, readData1)
        let readData2 = try subject.read(upToCount: Int.max)
        XCTAssertNil(readData2)
    }

    func test_read_throwsErrorWhenStreamIsClosedWithError() throws {
        let subject = BufferedStream()
        try subject.write(contentsOf: testData)
        subject.closeWithError(TestError.error)
        do {
            let readData1 = try subject.read(upToCount: Int.max)
        } catch TestError.error {
            // Test passes
        } catch {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
        }
    }

    // MARK: - readToEnd()

    func test_readToEnd_readsToEnd() throws {
        let subject = BufferedStream(data: testData)
        subject.close()

        let readData = try subject.readToEnd()
        XCTAssertEqual(readData, testData)

        // read again, should return nil
        let readData2 = try subject.readToEnd()
        XCTAssertNil(readData2)
    }

    func test_readToEnd_throwsErrorWhenStreamIsClosedWithError() throws {
        let subject = BufferedStream()
        try subject.write(contentsOf: testData)
        subject.closeWithError(TestError.error)
        do {
            let readData1 = try subject.readToEnd()
        } catch TestError.error {
            // Test passes
        } catch {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
        }
    }

    // MARK: - readToEndAsync()

    func test_readToEndAsync_readsToEnd() async throws {
        let subject = BufferedStream(data: testData)
        subject.close()

        let readData = try await subject.readToEndAsync()
        XCTAssertEqual(readData, testData)

        // read again, should return nil
        let readData2 = try await subject.readToEndAsync()
        XCTAssertNil(readData2)
    }

    func test_readToEndAsync_throwsErrorWhenStreamIsClosedWithError() async throws {
        let subject = BufferedStream()
        try subject.write(contentsOf: testData)
        subject.closeWithError(TestError.error)
        do {
            let readData1 = try await subject.readToEndAsync()
        } catch TestError.error {
            // Test passes
        } catch {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
        }
    }

    // MARK: - readAsync(upToCount:)

    func test_readAsync_readsAsynchronously() async throws {
        let subject = BufferedStream(data: testData)
        let readData = try await subject.readAsync(upToCount: Int.max)
        XCTAssertEqual(testData, readData)
    }

    func test_readAsync_readsAsynchronouslyUpToCount() async throws {
        let subject = BufferedStream(data: testData)
        let readData1 = try await subject.readAsync(upToCount: 4)
        XCTAssertEqual(testData[0..<4], readData1)
        let readData2 = try await subject.readAsync(upToCount: 4)
        XCTAssertEqual(testData[4..<8], readData2)
    }

    func test_readAsync_readsAsDataIsAddedToTheStream() async throws {
        let subject = BufferedStream()
        let testData1 = testData[0..<4]
        let testData2 = testData[4..<8]
        Task.detached(priority: .low) {
            await Task.yield()
            try subject.write(contentsOf: testData1)
        }
        let readData1 = try await subject.readAsync(upToCount: 4)
        XCTAssertEqual(testData1, readData1)
        Task.detached(priority: .low) {
            await Task.yield()
            try subject.write(contentsOf: testData2)
        }
        let readData2 = try await subject.readAsync(upToCount: 4)
        XCTAssertEqual(testData2, readData2)
    }

    func test_readAsync_readsRemainingDataWhenStreamIsClosedThenReadsNil() async throws {
        let subject = BufferedStream(data: testData)
        let readData1 = try await subject.readAsync(upToCount: 4)
        XCTAssertEqual(testData[0..<4], readData1)
        subject.close()
        let readData2 = try await subject.readAsync(upToCount: Int.max)
        XCTAssertEqual(testData[4...], readData2)
        let readData3 = try await subject.readAsync(upToCount: Int.max)
        XCTAssertNil(readData3)
    }

    func test_readAsync_throwsErrorWhenStreamIsClosedWithError() async throws {
        let subject = BufferedStream()
        try subject.write(contentsOf: testData)
        subject.closeWithError(TestError.error)
        do {
            let readData1 = try await subject.readAsync(upToCount: Int.max)
        } catch TestError.error {
            // Test passes
        } catch {
            XCTFail("Unexpected error thrown: \(error.localizedDescription)")
        }
    }

    // MARK: - write(contentsOf:)

    func test_write_appendsWrittenDataToBuffer() throws {
        let subject = BufferedStream(data: testData)
        try subject.write(contentsOf: additionalData)
        let readData1 = try subject.read(upToCount: Int.max)
        XCTAssertEqual(testData + additionalData, readData1)
    }

    // MARK: - length

    func test_length_returnsNilLengthBeforeStreamCloses() throws {
        let sut = BufferedStream(data: testData)

        XCTAssertNil(sut.length)
    }

    func test_length_returnsNilLengthAfterWriteAndBeforeStreamCloses() async throws {
        let sut = BufferedStream(data: testData)
        try sut.write(contentsOf: additionalData)

        XCTAssertNil(sut.length)
    }

    func test_length_returnsInitialLengthAfterStreamCloses() throws {
        let sut = BufferedStream(data: testData)

        sut.close()

        XCTAssertEqual(sut.length, testData.count)
    }

    func test_length_returnsTotalLengthAfterWriteAndAfterStreamCloses() async throws {
        let sut = BufferedStream(data: testData)
        try sut.write(contentsOf: additionalData)

        sut.close()

        XCTAssertEqual(sut.length, testData.count + additionalData.count)
    }

    func test_length_returnsDataLengthWhenCreatedAsAClosedStream() throws {
        let sut = BufferedStream(data: testData, isClosed: true)

        XCTAssertEqual(sut.length, testData.count)
    }
}

private enum TestError: Error, Equatable {
    case error
}

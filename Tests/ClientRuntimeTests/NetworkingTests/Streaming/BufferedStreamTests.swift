//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import ClientRuntime

final class BufferedStreamTests: XCTestCase {

    let testData = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A])

    func testRead() throws {
        let sut = BufferedStream(data: testData)
        try sut.close()

        // read up to 4 bytes
        let readData1 = try sut.read(upToCount: 4)
        XCTAssertEqual(readData1, Data([0x00, 0x01, 0x02, 0x03]))
        XCTAssertEqual(4, sut.position)
        XCTAssertEqual(sut.buffer, Data([0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A]))

        // read another 4 bytes
        let readData2 = try sut.read(upToCount: 4)
        XCTAssertEqual(readData2, Data([0x04, 0x05, 0x06, 0x07]))
        XCTAssertEqual(8, sut.position)
        XCTAssertEqual(sut.buffer, Data([0x08, 0x09, 0x0A]))

        // read another 2 bytes
        let readData3 = try sut.read(upToCount: 2)
        XCTAssertEqual(readData3, Data([0x08, 0x09]))
        XCTAssertEqual(10, sut.position)
        XCTAssertEqual(sut.buffer, Data([0x0A]))

        // read another 4 bytes, but only 1 byte is available
        let readData4 = try sut.read(upToCount: 4)
        XCTAssertEqual(readData4, Data([0x0A]))
        XCTAssertEqual(11, sut.position)
        XCTAssertEqual(sut.buffer, Data())

        // read another 4 bytes, but no bytes are available
        let readData5 = try sut.read(upToCount: 4)
        XCTAssertNil(readData5)
    }

    func testReadToEnd() {
        let sut = BufferedStream(data: testData)
        try! sut.close()

        let readData = try! sut.readToEnd()
        XCTAssertEqual(readData, testData)
        XCTAssertEqual(sut.buffer, Data())

        // read again, should return nil
        let readData2 = try! sut.readToEnd()
        XCTAssertNil(readData2)
    }

    func testSeek() throws {
        let sut = BufferedStream(data: testData)

        // seek to 2
        try! sut.seek(toOffset: 2)
        XCTAssertEqual(2, sut.position)

        // seek to 4
        try! sut.seek(toOffset: 4)
        XCTAssertEqual(4, sut.position)
    }

    func testWrite() throws {
        let sut = BufferedStream(data: testData)
        try sut.write(contentsOf: .init([0x0B, 0x0C, 0x0D, 0x0E]))
        XCTAssertEqual(sut.buffer, Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E]))
    }

    func testLength() throws {
        let sut = BufferedStream(data: testData)

        // length is 11
        XCTAssertEqual(sut.length, 11)

        // read 4 bytes, length is still 11
        _ = try sut.read(upToCount: 4)
        XCTAssertEqual(sut.length, 11)

        // write 4 bytes, length is 15
        try sut.write(contentsOf: .init([0x0B, 0x0C, 0x0D, 0x0E]))
        XCTAssertEqual(sut.length, 15)

        // read 2 bytes, length is still 15
        _ = try sut.read(upToCount: 4)
        XCTAssertEqual(sut.length, 15)

        // read 2 bytes, length is still 15
        _ = try sut.read(upToCount: 2)
        XCTAssertEqual(sut.length, 15)
    }
}

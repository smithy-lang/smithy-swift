//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import ClientRuntime

final class CachingStreamTests: XCTestCase {

    let testData = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A])

    func testRead() throws {
        let base = BufferedStream(data: testData)
        let sut = CachingStream(base: base)
        try sut.close()

        // read up to 4 bytes
        let readData1 = try sut.read(upToCount: 4)
        XCTAssertEqual(readData1, Data([0x00, 0x01, 0x02, 0x03]))
        XCTAssertEqual(4, sut.position)
        XCTAssertEqual(sut.cache, readData1)

        // read another 4 bytes
        let readData2 = try sut.read(upToCount: 4)
        XCTAssertEqual(readData2, Data([0x04, 0x05, 0x06, 0x07]))
        XCTAssertEqual(8, sut.position)
        XCTAssertEqual(sut.cache, readData1! + readData2!)

        // read another 2 bytes
        let readData3 = try sut.read(upToCount: 2)
        XCTAssertEqual(readData3, Data([0x08, 0x09]))
        XCTAssertEqual(10, sut.position)
        XCTAssertEqual(sut.cache, readData1! + readData2! + readData3!)

        // read another 4 bytes, but only 1 byte is available
        let readData4 = try sut.read(upToCount: 4)
        XCTAssertEqual(readData4, Data([0x0A]))
        XCTAssertEqual(11, sut.position)
        XCTAssertEqual(sut.cache, testData)

        // read another 4 bytes, but no bytes are available
        let readData5 = try sut.read(upToCount: 4)
        XCTAssertNil(readData5)
        XCTAssertEqual(sut.cache, testData)
    }

    func testReadToEnd() {
        let base = BufferedStream(data: testData)
        let sut = CachingStream(base: base)
        try! sut.close()

        let readData = try! sut.readToEnd()
        XCTAssertEqual(readData, testData)

        // read again, should return nil
        let readData2 = try! sut.readToEnd()
        XCTAssertNil(readData2)

        // seek to beginning
        try! sut.seek(toOffset: 0)
        XCTAssertEqual(sut.position, 0)
        let readData3 = try! sut.readToEnd()
        XCTAssertEqual(readData3, testData)
    }

    func testSeek() throws {
        let base = BufferedStream(data: testData)
        let sut = CachingStream(base: base)
        
        // seek to 2
        try! sut.seek(toOffset: 2)
        XCTAssertEqual(2, sut.position)

        // seek to 4
        try! sut.seek(toOffset: 4)
        XCTAssertEqual(4, sut.position)
    }

    func testWrite() throws {
        let base = BufferedStream(data: testData)
        let sut = CachingStream(base: base)

        try sut.write(contentsOf: .init([0x0B, 0x0C, 0x0D, 0x0E]))
        try sut.close()
        
        _ = try! sut.readToEnd()
        XCTAssertEqual(sut.cache, testData + Data([0x0B, 0x0C, 0x0D, 0x0E]))
    }

    func testLength() throws {
        let base = BufferedStream(data: testData)
        let sut = CachingStream(base: base)
        
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

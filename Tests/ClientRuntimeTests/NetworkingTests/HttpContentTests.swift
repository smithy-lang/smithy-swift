//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import ClientRuntime
import AwsCommonRuntimeKit

final class HttpContentTests: XCTestCase {

    let testData = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A])

    func testRead() throws {
        let sut = HttpContent(body: .data(testData))

        // read first 4 bytes
        let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: 4)
        let bytesRead1 = try sut.read(buffer: buffer)
        let bytes1 = Data(bytes: buffer.baseAddress!, count: bytesRead1!)
        XCTAssertEqual(bytesRead1, 4)
        XCTAssertEqual(bytes1, Data([0x00, 0x01, 0x02, 0x03]))

        // read next 4 bytes from current position
        let bytesRead2 = try sut.read(buffer: buffer)
        let bytes2 = Data(bytes: buffer.baseAddress!, count: bytesRead2!)
        XCTAssertEqual(bytesRead2, 4)
        XCTAssertEqual(bytes2, Data([0x04, 0x05, 0x06, 0x07]))

        // read next 4 bytes from current position
        // this should only read 3 bytes since we are at the end of the stream
        let bytesRead3 = try sut.read(buffer: buffer)
        let bytes3 = Data(bytes: buffer.baseAddress!, count: bytesRead3!)
        XCTAssertEqual(bytesRead3, 3)
        XCTAssertEqual(bytes3, Data([0x08, 0x09, 0x0A]))

        // read next 4 bytes from current position
        // this should return nil since we are at the end of the stream
        let bytesRead4 = try sut.read(buffer: buffer)
        XCTAssertNil(bytesRead4)
    }

    func testSeek() throws {
        let sut = HttpContent(body: .data(testData))

        // read first 4 bytes
        let buffer = UnsafeMutableBufferPointer<UInt8>.allocate(capacity: 4)
        let bytesRead1 = try sut.read(buffer: buffer)
        let bytes1 = Data(bytes: buffer.baseAddress!, count: bytesRead1!)
        XCTAssertEqual(bytesRead1!, 4)
        XCTAssertEqual(bytes1, Data([0x00, 0x01, 0x02, 0x03]))

        // seek to offset 2 and read 4 bytes
        try sut.seek(offset: 2, streamSeekType: .begin)
        let bytesRead2 = try sut.read(buffer: buffer)
        let bytes2 = Data(bytes: buffer.baseAddress!, count: bytesRead2!)
        XCTAssertEqual(bytesRead2!, 4)
        XCTAssertEqual(bytes2, Data([0x02, 0x03, 0x04, 0x05]))

        // seek to offset 8 and read 3 bytes
        // this should only read 3 bytes since we are at the end of the stream
        try sut.seek(offset: 8, streamSeekType: .begin)
        let bytesRead3 = try sut.read(buffer: buffer)
        let bytes3 = Data(bytes: buffer.baseAddress!, count: bytesRead3!)
        XCTAssertEqual(bytesRead3!, 3)
        XCTAssertEqual(bytes3, Data([0x08, 0x09, 0x0A]))
    }
}

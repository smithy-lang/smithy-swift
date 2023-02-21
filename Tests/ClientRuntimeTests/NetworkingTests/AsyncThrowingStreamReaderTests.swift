/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import XCTest
@testable import ClientRuntime

final class AsyncThrowingStreamReaderTests: XCTestCase {
    func testRead() async {
        let stream = AsyncThrowingStream<Data, Error> { continuation in
            continuation.yield(Data([0x00, 0x01, 0x02, 0x03]))
            continuation.yield(Data([0x04, 0x05, 0x06, 0x07]))
            continuation.yield(Data([0x08, 0x09]))
            continuation.yield(Data([0x0A]))
            continuation.finish()
        }

        let sut = AsyncThrowingStreamReader(stream: stream)
        let readBytes = try! await sut.read(upToCount: nil)
        XCTAssertEqual(readBytes, Data([0x00, 0x01, 0x02, 0x03]))

        let readBytes2 = try! await sut.read(upToCount: nil)
        XCTAssertEqual(readBytes2, Data([0x04, 0x05, 0x06, 0x07]))

        let readBytes3 = try! await sut.read(upToCount: nil)
        XCTAssertEqual(readBytes3, Data([0x08, 0x09]))

        let readBytes4 = try! await sut.read(upToCount: nil)
        XCTAssertEqual(readBytes4, Data([0x0A]))
    }
}

//
 // Copyright Amazon.com Inc. or its affiliates.
 // All Rights Reserved.
 //
 // SPDX-License-Identifier: Apache-2.0
 //

 import XCTest
 @testable import ClientRuntime

 final class DataStreamReaderTests: XCTestCase {

     let testData = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A])

     func testRead() throws {
         let sut = DataStreamReader(data: testData)
         let readByteBuffer = sut.read(maxBytes: 4, rewind: false)
         let readBytes = readByteBuffer.getData()
         XCTAssertEqual(readBytes, Data([0x00, 0x01, 0x02, 0x03]))

         let readByteBuffer2 = sut.read(maxBytes: 4)
         let readBytes2 = readByteBuffer2.getData()
         XCTAssertEqual(readBytes2, Data([0x04, 0x05, 0x06, 0x07]))

         let readByteBuffer3 = sut.read(maxBytes: 2)
         let readBytes3 = readByteBuffer3.getData()
         XCTAssertEqual(readBytes3, Data([0x08, 0x09]))

         let readByteBuffer4 = sut.read(maxBytes: 2)
         let readBytes4 = readByteBuffer4.getData()
         XCTAssertEqual(readBytes4, Data([0x0A]))
     }

     func testSeek() {
         let sut = DataStreamReader(data: testData)
         try! sut.seek(offset: 2)
         let readByteBuffer = sut.read(maxBytes: 4)
         let readBytes = readByteBuffer.getData()
         XCTAssertEqual(readBytes, Data([0x02, 0x03, 0x04, 0x05]))

         try! sut.seek(offset: 2)
         let readByteBuffer2 = sut.read(maxBytes: 2)
         let readBytes2 = readByteBuffer2.getData()
         XCTAssertEqual(readBytes2, Data([0x02, 0x03]))
     }

     func testWrite() {
         let sut = DataStreamReader(data: testData)
         sut.write(buffer: .init(data: .init([0x0B, 0x0C, 0x0D, 0x0E])))
         XCTAssertEqual(sut.byteBuffer.getData(), Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E]))
     }

     func testAvailableForRead() {
         let sut = DataStreamReader(data: testData)
         XCTAssertEqual(sut.availableForRead, 11)
         _ = sut.read(maxBytes: 4)
         XCTAssertEqual(sut.availableForRead, 7)
         _ = sut.read(maxBytes: 4)
         XCTAssertEqual(sut.availableForRead, 3)
         _ = sut.read(maxBytes: 2)
         XCTAssertEqual(sut.availableForRead, 1)
         _ = sut.read(maxBytes: 2)
         XCTAssertEqual(sut.availableForRead, 0)
     }

     func testContentLength() {
         let sut = DataStreamReader(data: testData)
         XCTAssertEqual(sut.contentLength, 11)

         _ = sut.read(maxBytes: 4)
         XCTAssertEqual(sut.contentLength, 11)

         _ = sut.read(maxBytes: 4)
         XCTAssertEqual(sut.contentLength, 11)

         _ = sut.read(maxBytes: 2)
         XCTAssertEqual(sut.contentLength, 11)
     }
 }
//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import ClientRuntime
import AwsCommonRuntimeKit
import XCTest

class DataStreamReaderTests: XCTestCase {
    let testData = Data([0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A])
    
    func testRead() {
        let byteBuffer = ByteBuffer(data: testData)
        let dataStreamReader = DataStreamReader(byteBuffer: byteBuffer)
        
        let firstRead = dataStreamReader.read().getData()
        XCTAssertEqual(firstRead, testData)
        
        let secondRead = dataStreamReader.read().getData()
        XCTAssertNotEqual(secondRead, testData)
        XCTAssertEqual(secondRead, Data())
    }
    
    func testReadWithRewind() {
        let byteBuffer = ByteBuffer(data: testData)
        let dataStreamReader = DataStreamReader(byteBuffer: byteBuffer)
        
        let firstRead = dataStreamReader.read(rewind: true).getData()
        XCTAssertEqual(firstRead, testData)
        
        let secondRead = dataStreamReader.read().getData()
        XCTAssertEqual(secondRead, testData)
    }
    
    func testWriteThenReadWithRewind() {
        let dataStreamReader = DataStreamReader()
        
        let byteBuffer = ByteBuffer(data: testData)
        dataStreamReader.write(buffer: byteBuffer)
        
        let firstRead = dataStreamReader.read(rewind: true).getData()
        XCTAssertEqual(firstRead, testData)
        
        let secondRead = dataStreamReader.read().getData()
        XCTAssertEqual(secondRead, testData)
        
        let thirdRead = dataStreamReader.read().getData()
        XCTAssertNotEqual(thirdRead, testData)
        XCTAssertEqual(thirdRead, Data())
    }
}

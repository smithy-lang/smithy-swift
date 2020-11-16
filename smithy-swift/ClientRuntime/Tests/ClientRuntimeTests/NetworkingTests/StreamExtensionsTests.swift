//
// Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License").
// You may not use this file except in compliance with the License.
// A copy of the License is located at
//
// http://aws.amazon.com/apache2.0
//
// or in the "license" file accompanying this file. This file is distributed
// on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied. See the License for the specific language governing
// permissions and limitations under the License.
//

import XCTest
import ClientRuntime

class StreamExtensionsTests: XCTestCase {
    
    let testString = "test@123"
    var dataForStream: Data!
    
    override func setUp() {
        dataForStream = String(testString).data(using: .utf8)
    }

    func testReadingDataFromInputStream() {
        let inputStream = InputStream(data: dataForStream!)
        
        let readData = try? inputStream.readData(maxLength: 4)
        XCTAssertNotNil(readData)
        
        print(String(data: readData!, encoding: .utf8) ?? "")
    }

    func testWritingDataToOutputStream() {
        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            buffer.deallocate()
        }
        let outputStream = OutputStream(toBuffer: buffer, capacity: bufferSize)
        print(dataForStream!)

        let writtenBytesCount = try? outputStream.write(dataForStream)
        
        XCTAssertNotNil(writtenBytesCount)
        print(writtenBytesCount ?? 0)
    }
}

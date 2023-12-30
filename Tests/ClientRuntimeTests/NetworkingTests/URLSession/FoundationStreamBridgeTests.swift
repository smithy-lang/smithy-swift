//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import ClientRuntime

class FoundationStreamBridgeTests: XCTestCase {

    func test_open_streamsAllDataToOutputBuffer() async throws {
        // Our test data may be 100 to 1000 bytes long
        let dataSize = Int.random(in: 100...1000)

        // The buffer may be as small as 4 bytes, up to 1.5x as big as the data
        let bufferSize = Int.random(in: 4...1500)

        // Fill a data buffer with dataSize random numbers
        let originalData = Data((0...dataSize).map { _ in UInt8.random(in: UInt8.min...UInt8.max) })

        // Create a stream bridge with our original data & open it
        let bufferedStream = BufferedStream(data: originalData, isClosed: true)
        let subject = FoundationStreamBridge(readableStream: bufferedStream, bufferSize: bufferSize)
        subject.open()

        // This will hold the data that is bridged from the ReadableStream to the Foundation InputStream
        var bridgedData = Data()

        // Create a temp buffer we can use to copy the input stream bytes
        var temp = Data(count: bufferSize)

        // Open the input stream & read it to exhaustion
        subject.inputStream.open()
        while !subject.exhausted {
            temp.withUnsafeMutableBytes { bufferPtr in
                let bytePtr = bufferPtr.bindMemory(to: UInt8.self).baseAddress!

                // Copy the input stream to the temp buffer.  When count is positive,
                // bytes were read
                let count = subject.inputStream.read(bytePtr, maxLength: bufferSize)
                if count > 0 {
                    // Add the read bytes onto the bridged data
                    bridgedData.append(bytePtr, count: count)
                    print("Read \(count) bytes, buffer: \(bridgedData.count) total")
                }
            }
        }
        // Once the subject is exhausted, all data should have been bridged and the subject may be closed
        subject.close()

        // Verify data was all bridged
        XCTAssertEqual(bridgedData, originalData)
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(watchOS) || os(tvOS) || os(visionOS)

import Foundation
import XCTest
@testable import ClientRuntime

class FoundationStreamBridgeTests: XCTestCase {

    func test_open_streamsAllDataToOutputBuffer() async throws {

        // FoundationStreamBridge is susceptible to spurious bugs due to data races & other
        // not readily reproducible causes, so run this test repeatedly to help uncover
        // problems
        for run in 1...10_000 {

            // Our test data may be 100 to 1000 bytes long
            let dataSize = Int.random(in: 100...1000)

            // The buffer may be as small as 4 bytes, up to 1.5x as big as the max data size
            let bufferSize = Int.random(in: 4...1500)

            // Fill a data buffer with dataSize random numbers
            let originalData = Data((0...dataSize).map { _ in UInt8.random(in: UInt8.min...UInt8.max) })

            // Create a stream bridge with our original data & open it
            let bufferedStream = BufferedStream(data: originalData, isClosed: true)
            let subject = FoundationStreamBridge(readableStream: bufferedStream, bufferSize: bufferSize)
            await subject.open()

            // This will hold the data that is bridged from the ReadableStream to the Foundation InputStream
            var bridgedData = Data()

            // Create a temp buffer we can use to copy the input stream bytes
            // We are responsible for deallocating it
            let temp = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
            defer { temp.deallocate() }

            // Open the input stream & read it to exhaustion
            subject.inputStream.open()
            while !subject.exhausted || subject.inputStream.hasBytesAvailable {
                // Copy the input stream to the temp buffer.  When count is positive,
                // bytes were read
                let count = subject.inputStream.read(temp, maxLength: bufferSize)
                if count > 0 {
                    // Add the read bytes onto the bridged data
                    bridgedData.append(temp, count: count)
                }
            }
            // Once the subject is exhausted, all data should have been bridged and the subject may be closed
            await subject.close()

            // Verify data was all bridged
            XCTAssertEqual(bridgedData, originalData, "Run \(run) failed (dataSize: \(dataSize), bufferSize: \(bufferSize)")
        }
    }
}

#endif

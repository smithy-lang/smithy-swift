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

        // The maximum size of input streaming data in the tests
        let maxDataSize = 10_000

        // The max size of the buffer for data being streamed.
        let maxBufferSize = 2 * maxDataSize

        // Create & fill a buffer with random bytes, for use in later test setup
        // Random buffer is reused because creating random data is slow
        // We are responsible for deallocating it
        let randomBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: maxDataSize)
        defer { randomBuffer.deallocate() }

        for i in 0..<maxDataSize {
            randomBuffer[i] = UInt8.random(in: UInt8.min...UInt8.max)
        }

        // Create a temp buffer we can use to copy the input stream bytes
        // We are responsible for deallocating it
        let tempBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: maxDataSize)
        defer { tempBuffer.deallocate() }

        // FoundationStreamBridge is susceptible to spurious bugs due to data races & other
        // not readily reproducible causes, so run this test repeatedly to help uncover
        // problems
        for run in 1...maxDataSize {

            // Run a test for every possible data size
            let dataSize = run

            // The buffer may be as small as 1 byte, up to 2x as big as the max data size capped by maxBufferSize
            let bufferSize = Int.random(in: 1...(min(max(2 * dataSize, 1), maxBufferSize)))

            // Fill a data buffer with dataSize random numbers
            let originalData = Data(bytes: randomBuffer, count: dataSize)

            // Create a stream bridge with our original data & open it
            let bufferedStream = BufferedStream(data: originalData, isClosed: true)
            let subject = FoundationStreamBridge(readableStream: bufferedStream, bufferSize: bufferSize)
            await subject.open()

            // This will hold the data that is bridged from the ReadableStream to the Foundation InputStream
            var bridgedData = Data()

            // Open the input stream & read it to either end-of-data or a stream error
            subject.inputStream.open()
            while ![.atEnd, .error].contains(subject.inputStream.streamStatus) {

                // Copy the input stream to the temp buffer.  When count is positive, bytes were read
                let count = subject.inputStream.read(tempBuffer, maxLength: bufferSize)
                if count > 0 {
                    // Add the read bytes onto the bridged data
                    bridgedData.append(tempBuffer, count: count)
                } else if count < 0 {
                    XCTAssertNil(subject.inputStream.streamError)
                }
            }
            // Once the subject is exhausted, all data should have been bridged and the subject may be closed
            await subject.close()

            // Close the inputStream as well
            subject.inputStream.close()

            // Fail in the event of a stream error
            XCTAssertNil(subject.inputStream.streamError, "Stream failed with error: \(subject.inputStream.streamError?.localizedDescription ?? "")")

            // Verify data was all bridged
            XCTAssertEqual(bridgedData, originalData, "Run \(run) failed (dataSize: \(dataSize), bufferSize: \(bufferSize)")
        }
    }
}

#endif

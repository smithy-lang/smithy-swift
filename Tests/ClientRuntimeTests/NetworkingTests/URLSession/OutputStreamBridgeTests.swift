//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import XCTest
@testable import ClientRuntime

class OutputStreamBridgeTests: XCTestCase {

    func test_OSB_streamsAllDataToOutputBuffer() async throws {
        let originalData = UUID().uuidString.data(using: .utf8)
        let bufferedStream = BufferedStream(data: originalData, isClosed: true)
        let outputStream = OutputStream(toMemory: ())
        let subject = OutputStreamBridge(readableStream: bufferedStream, outputStream: outputStream)
        subject.open()
        while outputStream.streamStatus != .closed { try await Task.sleep(nanoseconds: 10_000_000) }
        XCTAssertEqual(outputStream.property(forKey: .dataWrittenToMemoryStreamKey) as? Data, originalData)
    }
}

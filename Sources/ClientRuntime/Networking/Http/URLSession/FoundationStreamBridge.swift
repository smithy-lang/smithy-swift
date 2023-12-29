//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class FoundationStreamBridge: NSObject, StreamDelegate {
    /// The `ReadableStream` that will serve as the input to this bridge.
    /// The bridge will read bytes from this stream and dump them to the Foundation stream
    /// pair  as they become available.
    let readableStream: ReadableStream

    /// The max number of bytes to buffer internally (and transfer) at any given time.
    let bufferSize: Int

    /// A Foundation stream that will carry the bytes read from the readableStream as they become available.
    let foundationInputStream: InputStream

    private let foundationOutputStream: OutputStream
    private var buffer: Data
    private var thread: Thread?

    // MARK: - init & deinit

    init(readableStream: ReadableStream, bufferSize: Int = 1024) {
        self.readableStream = readableStream
        self.bufferSize = bufferSize
        var inputStream: InputStream?
        var outputStream: OutputStream?
        Foundation.Stream.getBoundStreams(
            withBufferSize: bufferSize, inputStream: &inputStream, outputStream: &outputStream
        )
        guard let inputStream, let outputStream else {
            fatalError("Get pair of bound streams failed.  Please file a bug with AWS SDK for Swift to report.")
        }
        self.foundationInputStream = inputStream
        self.foundationOutputStream = outputStream
        self.buffer = Data(capacity: bufferSize)
    }

    // MARK: - Opening & closing

    func open() {
        thread = Thread(block: {
            self.foundationOutputStream.delegate = self
            self.foundationOutputStream.schedule(in: RunLoop.current, forMode: .default)
            self.foundationOutputStream.open()
            RunLoop.current.run()
        })
        thread?.start()
    }

    func close() {
        foundationOutputStream.close()
        foundationInputStream.close()
        thread?.cancel()
        thread = nil
    }

    // MARK: - Writing to bridge

    private func writeToOutput() async throws {
        let data = try await readableStream.readAsync(upToCount: bufferSize - buffer.count)
        guard let data = data else {
            foundationOutputStream.close()
            thread?.cancel()
            return
        }
        buffer.append(data)
        guard !buffer.isEmpty else { return }
        buffer.withUnsafeBytes { bufferPtr in
            let bytePtr = bufferPtr.bindMemory(to: UInt8.self).baseAddress!
            let result = foundationOutputStream.write(bytePtr, maxLength: buffer.count)
            if result > 0 {
                print("OUTPUTSTREAMBRIDGE WROTE \(result) BYTES")
                buffer.removeFirst(result)
            }
        }
    }

    // MARK: - StreamDelegate protocol

    @objc func stream(_ aStream: Foundation.Stream, handle eventCode: Foundation.Stream.Event) {
        switch eventCode {
        case .hasSpaceAvailable:
            Task { try await writeToOutput() }
        default:
            break
        }
    }
}

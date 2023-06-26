//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class OutputStreamBridge: NSObject, StreamDelegate {
    let readableStream: ReadableStream
    let outputStream: OutputStream
    private var buffer = Data()
    private var thread: Thread?

    init(readableStream: ReadableStream, outputStream: OutputStream) {
        self.readableStream = readableStream
        self.outputStream = outputStream
    }

    func open() {
        print("OPEN OUTPUT STREAM")
        thread = Thread(block: {
            self.outputStream.delegate = self
            self.outputStream.schedule(in: RunLoop.current, forMode: .default)
            self.outputStream.open()
            RunLoop.current.run()
            print("STREAM IS NOW OPEN")
        })
        thread?.start()
    }

    func writeToOutput() async throws {
        print("WRITE TO OUTPUT")
        let data = try await readableStream.readAsync(upToCount: 4096 - buffer.count)
        guard let data = data else {
            outputStream.close()
            thread?.cancel()
            print("CLOSED STREAM")
            return
        }
        print("HAVE \(data.count) NEW BYTES")
        buffer.append(data)
        guard !buffer.isEmpty else { return }
        print("BUFFER: \"\(String(data: buffer, encoding: .utf8))\"")
        buffer.withUnsafeBytes { bufferPtr in
            let bytePtr = bufferPtr.bindMemory(to: UInt8.self).baseAddress!
            let result = outputStream.write(bytePtr, maxLength: buffer.count)
            if result > 0 {
                buffer.removeFirst(result)
            }
        }
    }

    @objc func stream(_ aStream: Foundation.Stream, handle eventCode: Foundation.Stream.Event) {
        switch eventCode {
        case .openCompleted:
            print("openCompleted")
        case .hasSpaceAvailable:
            print("hasSpaceAvailable")
            Task {
                try await writeToOutput()
            }
        case .hasBytesAvailable:
            print("hasBytesAvailable")
        case .endEncountered:
            print("endEncountered")
        case .errorOccurred:
            print("errorOccurred")
        default:
            break
        }
    }
}

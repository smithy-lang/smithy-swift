//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(watchOS) || os(tvOS) || os(visionOS)

import func Foundation.CFWriteStreamSetDispatchQueue
import class Foundation.DispatchQueue
import class Foundation.NSObject
import class Foundation.Stream
import class Foundation.InputStream
import class Foundation.OutputStream
import class Foundation.Thread
import class Foundation.RunLoop
import class Foundation.Timer
import struct Foundation.TimeInterval
import protocol Foundation.StreamDelegate

/// Reads data from a smithy-swift native `ReadableStream` and streams the data to a Foundation `InputStream`.
///
/// Used to permit SDK streaming request bodies to be used with `URLSession`-based HTTP requests.
class FoundationStreamBridge: NSObject, StreamDelegate {

    /// The max number of bytes to buffer internally (and transfer) at any given time.
    let bufferSize: Int

    /// A buffer to hold data that has been read from the ReadableStream but not yet written to the OutputStream.
    private var buffer: Data

    /// The `ReadableStream` that will serve as the input to this bridge.
    /// The bridge will read bytes from this stream and dump them to the Foundation stream
    /// pair  as they become available.
    let readableStream: ReadableStream

    /// A Foundation stream that will carry the bytes read from the readableStream as they become available.
    let inputStream: InputStream

    /// A Foundation `OutputStream` that will read from the `ReadableStream`
    private let outputStream: OutputStream

    /// A Logger for logging events.
    private let logger: LogAgent

    /// Actor used to ensure writes are performed in series.
    actor WriteCoordinator {
        var task: Task<Void, Error>?

        /// `true` if the readable stream has been found to be empty, `false` otherwise.  Will flip to `true` if the readable stream is read,
        /// and `nil` is returned.
        var readableStreamIsEmpty = false

        /// Sets stream status to indicate the stream is empty.
        func setReadableStreamIsEmpty() async {
            readableStreamIsEmpty = true
        }

        /// Creates a new concurrent Task that executes the passed block, ensuring that the previous Task
        /// finishes before this task starts.
        ///
        /// Acts as a sort of "serial queue" of Swift concurrency tasks.
        /// - Parameter block: The code to be performed in this task.
        func perform(_ block: @escaping @Sendable (WriteCoordinator) async throws -> Void) {
            self.task = Task { [task] in
                _ = await task?.result
                try await block(self)
            }
        }
    }

    /// Actor used to enforce the order of multiple concurrent stream writes.
    private let writeCoordinator = WriteCoordinator()

    /// A shared serial DispatchQueue to run the stream operations.
    /// Performing operations on an async queue allows Swift concurrency tasks to not block.
    private let queue = DispatchQueue(label: "AWSFoundationStreamBridge")

    // MARK: - init & deinit

    /// Creates a stream bridge taking the passed `ReadableStream` as its input
    ///
    /// Data will be buffered in an internal, in-memory buffer.  The Foundation `InputStream` that exposes `readableStream`
    /// is exposed by the `inputStream` property after creation.
    /// - Parameters:
    ///   - readableStream: The `ReadableStream` that serves as the input to the bridge.
    ///   - bufferSize: The number of bytes in the in-memory buffer.  The buffer is allocated for this size no matter if in use or not.
    ///   Defaults to 65536 bytes.
    init(readableStream: ReadableStream, bufferSize: Int = 65_536, logger: LogAgent) {
        var inputStream: InputStream?
        var outputStream: OutputStream?

        // Create a "bound stream pair" of Foundation streams.
        // Data written into the output stream will automatically flow to the inputStream for reading.
        // The bound streams have a buffer between them of size equal to the buffer held by this bridge.
        Foundation.Stream.getBoundStreams(
            withBufferSize: bufferSize, inputStream: &inputStream, outputStream: &outputStream
        )
        guard let inputStream, let outputStream else {
            // Fail with fatalError since this is not a failure that would happen in normal operation.
            fatalError("Get pair of bound streams failed.  Please file a bug with AWS SDK for Swift.")
        }
        self.bufferSize = bufferSize
        self.buffer = Data(capacity: bufferSize)
        self.readableStream = readableStream
        self.inputStream = inputStream
        self.outputStream = outputStream
        self.logger = logger

        // The output stream is configured to deliver its callbacks on the dispatch queue.
        // This precludes the need for a Thread with RunLoop.
        // For safety, all interactions with the output stream will be performed on this queue.
        CFWriteStreamSetDispatchQueue(outputStream, queue)
    }

    // MARK: - Opening & closing

    /// Schedule the output stream on the queue for stream callbacks.
    /// Do not wait to complete opening before returning.
    func open() async {
        await withCheckedContinuation { continuation in
            queue.async {
                self.outputStream.delegate = self
                self.outputStream.open()
                continuation.resume()
            }
        }
    }

    /// Unschedule the output stream on the special stream callback thread.
    /// Do not wait to complete closing before returning.
    func close() async {
        await withCheckedContinuation { continuation in
            queue.async {
                self.outputStream.close()
                self.outputStream.delegate = nil
                continuation.resume()
            }
        }
    }

    // MARK: - Writing to bridge

    /// Tries to read from the readable stream if possible, then transfer the data to the output stream.
    private func writeToOutput() async throws {
        await writeCoordinator.perform { [self] writeCoordinator in
            var data = Data()
            if await !writeCoordinator.readableStreamIsEmpty {
                if let newData = try await readableStream.readAsync(upToCount: bufferSize) {
                    data = newData
                } else {
                    await writeCoordinator.setReadableStreamIsEmpty()
                    await close()
                }
            }
            try await writeToOutputStream(data: data)
        }
    }

    /// Write the passed data to the output stream, using the reserved thread.
    private func writeToOutputStream(data: Data) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async { [self] in
                guard !buffer.isEmpty || !data.isEmpty else { continuation.resume(); return }
                buffer.append(data)
                var writeCount = 0
                buffer.withUnsafeBytes { bufferPtr in
                    guard let bytePtr = bufferPtr.bindMemory(to: UInt8.self).baseAddress else { return }
                    writeCount = outputStream.write(bytePtr, maxLength: buffer.count)
                }
                if writeCount > 0 {
                    logger.info("FoundationStreamBridge: wrote \(writeCount) bytes to request body")
                    buffer.removeFirst(writeCount)
                }
                if let error = outputStream.streamError {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    // MARK: - StreamDelegate protocol

    /// The stream places this callback when appropriate.  Call will be delivered on the GCD queue for stream callbacks.
    /// `.hasSpaceAvailable` prompts this type to query the readable stream for more data.
    @objc func stream(_ aStream: Foundation.Stream, handle eventCode: Foundation.Stream.Event) {
        switch eventCode {
        case .openCompleted:
            break
        case .hasBytesAvailable:
            break
        case .hasSpaceAvailable:
            // Since space is available, try and read from the ReadableStream and
            // transfer the data to the Foundation stream pair.
            // Use a `Task` to perform the operation within Swift concurrency.
            Task { try await writeToOutput() }
        case .errorOccurred:
            logger.info("FoundationStreamBridge: .errorOccurred event")
            logger.info("FoundationStreamBridge: Stream error: \(String(describing: aStream.streamError))")
        case .endEncountered:
            break
        default:
            logger.info("FoundationStreamBridge: Other stream event occurred: \(eventCode)")
        }
    }
}

#endif

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(watchOS) || os(tvOS) || os(visionOS)

import class Foundation.DispatchQueue
import func Foundation.autoreleasepool
import class Foundation.NSObject
import class Foundation.Stream
import class Foundation.InputStream
import class Foundation.OutputStream
import class Foundation.Thread
import class Foundation.RunLoop
import class Foundation.Timer
import struct Foundation.TimeInterval
import protocol Foundation.StreamDelegate
import Foundation

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

    /// A variable indicating that the streaming payload is chunked
    private var isChunkedTransfer: Bool

    public actor ChunkStorage {
        private var chunks: [(data: Data, isEndOfStream: Bool)] = []

        func popChunk() -> (data: Data, isEndOfStream: Bool)? {
            guard !chunks.isEmpty else {
                return nil
            }

            return chunks.removeFirst()
        }

        func addChunk(chunk: Data, isEndOfStream: Bool) {
            chunks.append((data: chunk, isEndOfStream: isEndOfStream))
        }

        func chunksAvailable() -> Int {
            return chunks.count
        }
    }

    public var chunksStorage = ChunkStorage()
    private var isFirstChunk = true

    /// Actor used to isolate the stream status from multiple concurrent accesses.
    actor ReadableStreamStatus {

        /// `true` if the readable stream has been found to be empty, `false` otherwise.  Will flip to `true` if the readable stream is read,
        /// and `nil` is returned.
        var isEmpty = false

        /// Sets stream status to indicate the stream is empty.
        func setIsEmpty() async {
            isEmpty = true
        }
    }

    /// Actor used to isolate the stream status from multiple concurrent accesses.
    private var readableStreamStatus = ReadableStreamStatus()

    /// A shared serial DispatchQueue to run the `perform`-on-thread operations.
    /// Performing thread operations on an async queue allows Swift concurrency tasks to not block.
    private static let queue = DispatchQueue(label: "AWSFoundationStreamBridge")

    /// Foundation Streams require a run loop on which to post callbacks for their delegates.
    /// All stream operations should be performed on the same thread as the delegate callbacks.
    /// A single shared `Thread` is started and is used to host the RunLoop for all Foundation Stream callbacks.
    private static let thread: Thread = {
        print("Starting thread configuration")
        let thread = Thread {
            autoreleasepool {
                let timer = Timer(timeInterval: TimeInterval.greatestFiniteMagnitude, repeats: true, block: { _ in })
                RunLoop.current.add(timer, forMode: .default)
                RunLoop.current.run(until: Date.distantFuture)
            }
        }
        thread.name = "AWSFoundationStreamBridge"
        thread.start()
        print("Thread start() called")
        return thread
    }()

    // MARK: - init & deinit

    /// Creates a stream bridge taking the passed `ReadableStream` as its input
    ///
    /// Data will be buffered in an internal, in-memory buffer.  The Foundation `InputStream` that exposes `readableStream`
    /// is exposed by the `inputStream` property after creation.
    /// - Parameters:
    ///   - readableStream: The `ReadableStream` that serves as the input to the bridge.
    ///   - bufferSize: The number of bytes in the in-memory buffer.  The buffer is allocated for this size no matter if in use or not.
    ///   Defaults to 4096 bytes.
    init(readableStream: ReadableStream, bufferSize: Int = 4096, isChunkedTransfer: Bool = false) {
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
        self.isChunkedTransfer = isChunkedTransfer
    }

    // MARK: - Opening & closing

    /// Schedule the output stream on the special thread reserved for stream callbacks.
    /// Do not wait to complete opening before returning.
    func open() async {
        await withCheckedContinuation { continuation in
            Self.queue.async {
                self.perform(#selector(self.openOnThread), on: Self.thread, with: nil, waitUntilDone: false)
            }
            continuation.resume()
        }
    }

    /// Configure the output stream to make StreamDelegate callback to this bridge using the special thread / run loop, and open the output stream.
    /// The input stream is not included here.  It will be configured by `URLSession` when the HTTP request is initiated.
    @objc private func openOnThread() {
        print("openOnThread() started")
        outputStream.delegate = self
        outputStream.schedule(in: RunLoop.current, forMode: .default)
        outputStream.open()
        print("openOnThread() complete")
    }

    /// Unschedule the output stream on the special stream callback thread.
    /// Do not wait to complete closing before returning.
    func close() async {
        await withCheckedContinuation { continuation in
            Self.queue.async {
                self.perform(#selector(self.closeOnThread), on: Self.thread, with: nil, waitUntilDone: false)
            }
            continuation.resume()
        }
    }

    /// Close the output stream and remove it from the thread / run loop.
    @objc private func closeOnThread() {
        outputStream.close()
        outputStream.remove(from: RunLoop.current, forMode: .default)
        outputStream.delegate = nil
    }

    // MARK: - Writing to bridge

    /// Tries to read from the readable stream if possible, then transfer the data to the output stream.
    private func writeToOutput() async throws {
        var data = Data()
        if await !readableStreamStatus.isEmpty {
            if let newData = try await readableStream.readAsync(upToCount: bufferSize) {
                data = newData
            } else {
                await readableStreamStatus.setIsEmpty()
                await close()
            }
        }
        try await writeToOutputStream(data: data)
    }

    private class WriteToOutputStreamResult: NSObject {
        var data = Data()
        var error: Error?
    }

    /// Write the passed data to the output stream, using the reserved thread.
    private func writeToOutputStream(data: Data) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            Self.queue.async {
                let result = WriteToOutputStreamResult()
                result.data = data
                let selector = #selector(self.writeToOutputStreamOnThread)
                self.perform(selector, on: Self.thread, with: result, waitUntilDone: true)
                if let error = result.error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    /// Append the new data to the buffer, then write to the output stream.  Return any error to the caller using the param object.
    @objc private func writeToOutputStreamOnThread(_ result: WriteToOutputStreamResult) {
        print("writeToOutputStreamOnThread() started")
        guard !buffer.isEmpty || !result.data.isEmpty else {
            return
        }
        buffer.append(result.data)
        var writeCount = 0
        buffer.withUnsafeBytes { bufferPtr in
            let bytePtr = bufferPtr.bindMemory(to: UInt8.self).baseAddress!
            writeCount = outputStream.write(bytePtr, maxLength: buffer.count)
        }
        if writeCount > 0 {
            buffer.removeFirst(writeCount)
        }
        result.error = outputStream.streamError
        print("writeToOutputStreamOnThread() complete")
    }

    func writeChunk(chunk: Data, endOfStream: Bool = false) async throws {
        print("writeChunk() started")
        if !chunk.isEmpty {
            try await writeToOutputStream(data: chunk)
        }

        if endOfStream {
            await self.readableStreamStatus.setIsEmpty()
            await self.close()
        }
        print("writeChunk() complete")
    }

    func handleChunk(_ chunk: Data, isEndOfStream: Bool) async throws {
        print("handleChunk() started")
        if isFirstChunk {
            // If it's the first chunk, write it immediately
            try await writeChunk(chunk: chunk, endOfStream: isEndOfStream)
            isFirstChunk = false // Update flag to indicate the first chunk has been handled
        } else {
            // For subsequent chunks, add them to the storage for later writing
            await self.chunksStorage.addChunk(chunk: chunk, isEndOfStream: isEndOfStream)
        }
        print("handleChunk() complete")
    }

    // MARK: - StreamDelegate protocol

    /// The stream places this callback when appropriate.  Call will be delivered on the special thread / run loop for stream callbacks.
    /// `.hasSpaceAvailable` prompts this type to query the readable stream for more data.
    @objc func stream(_ aStream: Foundation.Stream, handle eventCode: Foundation.Stream.Event) {
        switch eventCode {
        case .hasSpaceAvailable:
            // Since space is available, try and read from the ReadableStream and
            // transfer the data to the Foundation stream pair.
            // Use a `Task` to perform the operation within Swift concurrency.
            Task {
                if self.isChunkedTransfer {
                    guard let (nextChunk, isEndOfStream) = await self.chunksStorage.popChunk() else {
                        throw ClientError.dataNotFound("No more chunks to send!")
                    }
                    try await self.writeChunk(chunk: nextChunk, endOfStream: isEndOfStream)
                } else {
                    try await writeToOutput()
                }
            }
        case .errorOccurred:
            print("Stream error occurred: \(String(describing: aStream.streamError))")
        default:
            break
        }
    }
}

#endif

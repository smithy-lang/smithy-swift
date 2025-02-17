//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

#if os(iOS) || os(macOS) || os(watchOS) || os(tvOS) || os(visionOS)

import protocol Smithy.LogAgent
import protocol Smithy.ReadableStream
import struct Smithy.Attributes
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
import struct Foundation.Data
import protocol Foundation.StreamDelegate

/// Reads data from a smithy-swift native `ReadableStream` and streams the data through to a Foundation `InputStream`.
///
/// A pair of Foundation "bound streams" is created.  Data from the `ReadableStream` is transferred into the Foundation
/// `OutputStream` until the `ReadableStream` is closed and all data has been read from it.  The Foundation
/// `InputStream` is exposed as a property, and may be used to stream the data to other components.
///
/// Used to permit SDK streaming request bodies to be used with `URLSession`-based HTTP requests.
class FoundationStreamBridge: NSObject, StreamDelegate, @unchecked Sendable {

    /// The max number of bytes to buffer between the `ReadableStream` and the Foundation `OutputStream`
    /// at any given time.
    let bridgeBufferSize: Int

    /// The max number of bytes to buffer between the Foundation `OutputStream` and the Foundation `InputStream`
    /// at any given time.
    let boundStreamBufferSize: Int

    /// A buffer to hold data that has been read from the `ReadableStream` but not yet written to the
    /// Foundation `OutputStream`.  At most, it will contain `bridgeBufferSize` bytes.
    private var buffer: Data

    /// The `ReadableStream` that will serve as the input to this bridge.
    /// The bridge will read bytes from this stream and dump them to the Foundation stream
    /// pair as they become available.
    let readableStream: ReadableStream

    /// A Foundation stream that will carry the bytes read from the readableStream as they become available.
    ///
    /// May be replaced if needed by calling the `replaceStreams(_:)` method.
    var inputStream: InputStream

    /// A Foundation `OutputStream` that will read from the `ReadableStream`.
    ///
    /// Will be replaced when `replaceStreams(_:)` is called to replace the input stream.
    private var outputStream: OutputStream

    /// A Logger for logging events.
    private let logger: LogAgent

    /// HTTP Client Telemetry
    private let telemetry: HttpTelemetry

    /// Server address
    private let serverAddress: String

    /// Actor used to ensure writes are performed in series, one at a time.
    private actor WriteCoordinator {
        var task: Task<Void, Error>?

        /// Creates a new concurrent Task that executes the passed block, ensuring that the previous Task
        /// finishes before this task starts.
        ///
        /// Acts as a sort of "serial queue" of Swift concurrency tasks.
        /// - Parameter block: The code to be performed in this task.
        func perform(_ block: @escaping @Sendable () async throws -> Void) async throws {
            let task = Task { [task] in
                _ = await task?.result
                try await block()
            }
            self.task = task
            _ = try await task.value
        }
    }

    /// Actor used to enforce the order of multiple concurrent stream writes.
    private let writeCoordinator = WriteCoordinator()

    /// A serial `DispatchQueue` to run the stream operations for the Foundation `OutputStream`.
    ///
    /// Operations performed on the queue include:
    /// - Opening the stream
    /// - Closing the stream
    /// - Writing to the stream
    /// - Receiving `StreamDelegate` callbacks
    ///
    /// Queue operations are run in the order they are placed on the queue, and only one operation
    /// runs at a time (i.e. this is a "serial queue".)
    private let queue = DispatchQueue(label: "AWSFoundationStreamBridge")

    /// `true` if the readable stream has been closed, `false` otherwise.  Will be flipped to `true` once the readable stream is read,
    /// and `nil` is returned.
    ///
    /// Access this variable only during a write operation to ensure exclusive access.
    private var readableStreamIsClosed = false

    // MARK: - init & deinit

    /// Creates a stream bridge taking the passed `ReadableStream` as its input., and exposing a Foundation `InputStream`
    /// that may be used for streaming data on to Foundation components.
    ///
    /// Data will be buffered in an internal, in-memory buffer.  The Foundation `InputStream` that exposes `readableStream`
    /// is exposed by the `inputStream` property after creation.
    /// - Parameters:
    ///   - readableStream: The `ReadableStream` that serves as the input to the bridge.
    ///   - bridgeBufferSize: The number of bytes in the in-memory buffer.  The buffer is allocated for this size no matter if in use or not.
    ///   Defaults to 65536 bytes (64 kb).
    ///   - boundStreamBufferSize: The number of bytes in the buffer between the bound Foundation streams.  If `nil`, uses the
    ///   same size as `bridgeBufferSize`.  Defaults to `nil`.  Primary use of this parameter is for testing.
    ///   - logger: A logger that can be used to log stream events.
    init(
        readableStream: ReadableStream,
        bridgeBufferSize: Int = 65_536,
        boundStreamBufferSize: Int? = nil,
        logger: LogAgent,
        telemetry: HttpTelemetry,
        serverAddress: String = "unknown"
    ) {
        self.bridgeBufferSize = bridgeBufferSize
        self.boundStreamBufferSize = boundStreamBufferSize ?? bridgeBufferSize
        self.buffer = Data(capacity: bridgeBufferSize)
        self.readableStream = readableStream
        self.logger = logger
        self.telemetry = telemetry
        self.serverAddress = serverAddress
        (inputStream, outputStream) = Self.makeStreams(boundStreamBufferSize: self.boundStreamBufferSize, queue: queue)
    }

    func replaceStreams(completion: @escaping (InputStream?) -> Void) async {
        // Close the current output stream, since it will accept no more data and is about to
        // be replaced.
        await close()

        // Replace the bound stream pair with new bound streams.
        (inputStream, outputStream) = Self.makeStreams(boundStreamBufferSize: boundStreamBufferSize, queue: queue)

        // Call the completion block.  When this method is called from `urlSession(_:task:needNewBodyStream:)`,
        // the completion block will be that method's completion handler.
        completion(inputStream)

        // Re-open the `OutputStream` for writing.
        await open()
    }

    private static func makeStreams(boundStreamBufferSize: Int, queue: DispatchQueue) -> (InputStream, OutputStream) {
        var inputStream: InputStream?
        var outputStream: OutputStream?

        // Create a "bound stream pair" of Foundation streams.
        // Data written into the output stream will automatically flow to the inputStream for reading.
        // The bound streams have a buffer between them of size equal to the buffer held by this bridge.
        Foundation.Stream.getBoundStreams(
            withBufferSize: boundStreamBufferSize,
            inputStream: &inputStream,
            outputStream: &outputStream
        )
        guard let inputStream, let outputStream else {
            // Fail with fatalError since this is not a failure that would happen in normal operation.
            fatalError("Get pair of bound streams failed.  Please file a bug with AWS SDK for Swift.")
        }

        // The Foundation `OutputStream` is configured to deliver its callbacks on the dispatch queue.
        // This precludes the need for a Thread with RunLoop.
        // For safety, all interactions with the output stream will be performed on this queue.
        CFWriteStreamSetDispatchQueue(outputStream, queue)

        // Return the input & output streams to the caller in a tuple
        return (inputStream, outputStream)
    }

    // MARK: - Opening & closing

    /// Open the output stream and schedule this bridge to receive stream delegate callbacks.
    ///
    /// Stream operations are performed on the stream's queue.
    /// Stream opening is completed before asynchronous return to the caller.
    func open() async {
        await withCheckedContinuation { continuation in
            queue.async {
                self.outputStream.delegate = self
                self.outputStream.open()
                continuation.resume()
            }
        }
    }

    /// Close the output stream and unschedule this bridge from receiving stream delegate callbacks.
    ///
    /// Stream operations are performed on the stream's queue.
    /// Stream closing is completed before asynchronous return to the caller.
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

    /// Writes buffered data to the output stream.
    /// If the buffer is empty, the `ReadableStream` will be read first to replenish the buffer.
    ///
    /// If the buffer is empty and the readable stream is closed, there is no more data to bridge, and the output stream is closed.
    private func writeToOutput() async throws {

        // Perform the write on the `WriteCoordinator` to ensure that writes happen in-order
        // and one at a time.
        //
        // Note that it is safe to access `buffer` and `readableStreamIsClosed` instance vars
        // from inside the block passed to `perform()` because this is the only place
        // these instance vars are accessed, and the code in the `perform()` block runs
        // in series with any other calls to `perform()`.
        try await writeCoordinator.perform { [self] in

            // If there is no data in the buffer and the `ReadableStream` is still open,
            // attempt to read the stream.  Otherwise, skip reading the `ReadableStream` and
            // write what's in the buffer immediately.
            if !readableStreamIsClosed && buffer.isEmpty {
                if let newData = try await readableStream.readAsync(upToCount: bridgeBufferSize - buffer.count) {
                    buffer.append(newData)
                } else {
                    readableStreamIsClosed = true
                }
            }

            // Write the previously buffered data and/or newly read data, if any, to the Foundation `OutputStream`.
            // Capture the error from the stream write, if any.
            var streamError: Error?
            if !buffer.isEmpty {
                streamError = await writeToOutputStream()
            }

            // If the readable stream has closed and there is no data in the buffer,
            // there is nothing left to forward to the output stream, so close it.
            if readableStreamIsClosed && buffer.isEmpty {
                await close()
            }

            // If the output stream write produced an error, throw it now, else just return.
            if let streamError { throw streamError }
        }
    }

    /// Using the output stream's callback queue, write the buffered data to the Foundation `OutputStream`.
    ///
    /// After writing, remove the written data from the buffer.
    /// - Returns: The error resulting from the write to the Foundation `OutputStream`, or `nil` if no error occurred.
    private func writeToOutputStream() async -> Error? {

        // Suspend the caller while the write is performed on the Foundation `OutputStream`'s queue.
        await withCheckedContinuation { continuation in

            // Perform the write to the Foundation `OutputStream` on its queue.
            queue.async { [self] in

                // Write to the output stream.  It may not accept all data, so get the number of bytes
                // it accepted in `writeCount`.
                var writeCount = 0
                buffer.withUnsafeBytes { bufferPtr in
                    guard let bytePtr = bufferPtr.bindMemory(to: UInt8.self).baseAddress else { return }
                    writeCount = outputStream.write(bytePtr, maxLength: buffer.count)
                }

                // `writeCount` will be a positive number if bytes were written.
                // Remove the written bytes from the front of the buffer.
                if writeCount > 0 {
                    logger.debug("FoundationStreamBridge: wrote \(writeCount) bytes to request body")
                    buffer.removeFirst(writeCount)
                    // TICK - smithy.client.http.bytes_sent
                    var attributes = Attributes()
                    attributes.set(
                        key: HttpMetricsAttributesKeys.serverAddress,
                        value: serverAddress)
                    telemetry.bytesSent.add(
                        value: writeCount,
                        attributes: attributes,
                        context: telemetry.contextManager.current())
                }

                // Resume the caller now that the write is complete, returning the stream error, if any.
                continuation.resume(returning: outputStream.streamError)
            }
        }
    }

    // MARK: - StreamDelegate protocol

    /// The stream places this callback when an event happens.
    ///
    /// The `FoundationStreamBridge` sets itself as the delegate of the Foundation `OutputStream` whenever the
    /// `OutputStream` is open.  Stream callbacks will be delivered on the GCD serial queue.
    ///
    /// `.hasSpaceAvailable` is the only event where the `FoundationStreamBridge` takes action; in response to
    /// this event, the `FoundationStreamBridge` will write data to the `OutputStream`.
    ///
    /// This method is implemented for the Foundation `StreamDelegate` protocol.
    /// - Parameters:
    ///   - aStream: The stream which experienced the event.
    ///   - eventCode: A code describing the type of event that happened.
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
            logger.info("FoundationStreamBridge: Stream error: \(aStream.streamError.debugDescription)")
        case .endEncountered:
            break
        default:
            logger.info("FoundationStreamBridge: Other stream event occurred: \(eventCode)")
        }
    }
}

#endif

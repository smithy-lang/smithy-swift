//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import class Foundation.NSLock
import NIOCore
import protocol Smithy.Stream
import enum Smithy.StreamError

/// A `Stream` implementation backed by a FIFO queue of `NIOCore.ByteBuffer`s.
///
/// This is an opt-in, drop-in alternative to `SmithyStreams.BufferedStream` for the
/// SwiftNIO transport. It exists to avoid the byte copies that occur when streaming data
/// is round-tripped through `Foundation.Data`:
///
/// * **Writes** keep the producer's `ByteBuffer` as-is (copy-on-write — no byte copy) when
///   written through `writeBuffer(_:)` / `writeBufferAsync(_:)`.
/// * **Reads** vend `ByteBuffer` slices via `readSlice(length:)`, which shares storage and
///   advances the `readerIndex` — no `memmove`, no allocation. Use `readBufferAsync(upToCount:)`
///   for the zero-copy path; the `Data`-returning protocol methods perform a single boundary
///   copy only for legacy consumers that require `Data`.
///
/// Because it conforms to the existing public `Smithy.Stream` protocol, it slots into
/// `ByteStream.stream(_:)` with no public-API change; the NIO bridge detects it via `as?`.
///
/// Unlike `BufferedStream`, the async write path is **bounded**: a fast producer that writes
/// faster than the consumer reads is suspended once buffered data reaches `highWaterMark`, and
/// resumed once a read drains the buffer below the low-water mark. This restores the
/// demand-driven backpressure that NIO provides natively.
///
/// - Note: This class is thread-safe and async-safe.
///
/// ### Known prototype limitations (productionization TODOs)
/// * **Task cancellation:** the async `readBufferAsync` / `writeBufferAsync` / `writeAsync`
///   suspensions are not yet wrapped in `withTaskCancellationHandler`. A task cancelled while
///   parked is not eagerly removed/resumed; it is released when the next write, `close()`, or
///   `deinit` drains the queue. For production, add a cancellation handler that removes the
///   specific continuation under the lock and resumes it with `CancellationError`.
/// * **Synchronous `readToEnd()`:** like `BufferedStream`, the synchronous `readToEnd()` cannot
///   block, so it returns only what is buffered at call time. Call it only on a closed stream;
///   use `readToEndAsync()` to await all data on an open stream.
public final class ByteBufferStream: Stream, @unchecked Sendable {

    // MARK: - Stored state (guarded by `lock`)

    private let lock = NSLock()

    /// FIFO queue of buffers with bytes awaiting read. Every queued buffer has `readableBytes > 0`.
    /// We never `memmove` bytes between buffers; a fully-consumed buffer is dropped from the front.
    private var _chunks: [ByteBuffer] = []

    /// Index of the first not-yet-fully-consumed buffer in `_chunks`. Lets us advance without an
    /// `Array.removeFirst` on every read; the consumed prefix is compacted occasionally.
    private var _head = 0

    /// Sum of `readableBytes` across `_chunks[_head...]`.
    private var _bufferedBytes = 0

    /// Total bytes read out of the stream so far (the read position).
    private var _position = 0

    /// Total bytes ever written to the stream.
    private var _writtenBytes = 0

    private var _isClosed = false
    private var _length: Int?
    private var _error: Error?

    private let highWaterMark: Int
    private let lowWaterMark: Int

    private let allocator = ByteBufferAllocator()

    /// A reader suspended awaiting data, with the max number of bytes it requested.
    private struct SuspendedReader {
        let continuation: CheckedContinuation<ByteBuffer?, Error>
        let byteCount: Int
    }

    /// Suspended readers, FIFO (oldest first).
    private var _readers: [SuspendedReader] = []

    /// Suspended writers awaiting the buffer to drain below the low-water mark, FIFO.
    private var _writers: [CheckedContinuation<Void, Error>] = []

    // MARK: - Init / deinit

    /// Creates a new `ByteBufferStream`.
    /// - Parameters:
    ///   - highWaterMark: The number of buffered bytes at or above which an async writer is
    ///     suspended for backpressure. Defaults to 1 MiB.
    ///   - isClosed: Whether the stream begins closed.
    public init(highWaterMark: Int = 1 << 20, isClosed: Bool = false) {
        precondition(highWaterMark > 0, "highWaterMark must be positive")
        self.highWaterMark = highWaterMark
        self.lowWaterMark = max(1, highWaterMark / 2)
        self._isClosed = isClosed
        if isClosed { _length = 0 }
    }

    /// If released while readers/writers are still suspended, continue them so no continuation
    /// is left dangling.
    ///
    /// Drains the queues under the lock before resuming: a `CheckedContinuation` does not retain
    /// `self`, so in principle a concurrent `close()` could still be mid-flight. Taking the lock
    /// and emptying the arrays guarantees we cannot double-resume a continuation that `close()`
    /// already claimed. Resumes happen after `unlock()`.
    deinit {
        lock.lock()
        let readers = _readers; _readers.removeAll()
        let writers = _writers; _writers.removeAll()
        lock.unlock()
        readers.forEach { $0.continuation.resume(returning: nil) }
        writers.forEach { $0.resume() }
    }

    // MARK: - Stream metadata

    public var position: Data.Index { lock.withLock { _position } }
    public var length: Int? { lock.withLock { _length } }
    public var isEmpty: Bool { lock.withLock { _bufferedBytes == 0 } }
    public var isSeekable: Bool { false }

    /// Whether the stream has been closed.
    public var isClosed: Bool { lock.withLock { _isClosed } }

    /// The number of bytes currently buffered awaiting read.
    public var bufferCount: Int { lock.withLock { _bufferedBytes } }

    // MARK: - Core dequeue (call only while `lock` is held)

    /// Removes and returns up to `count` bytes from the front of the queue as a `ByteBuffer`
    /// slice (sharing storage, zero-copy), or `nil` if no bytes are currently buffered.
    private func _takeBuffer(upToCount count: Int) -> ByteBuffer? {
        guard count > 0, _head < _chunks.count else { return nil }
        var front = _chunks[_head]
        let take = min(count, front.readableBytes)
        // `readSlice` advances `front`'s readerIndex and returns a slice sharing storage. No copy.
        guard let slice = front.readSlice(length: take) else { return nil }
        if front.readableBytes == 0 {
            _head += 1
            // Compact the consumed prefix periodically so `_chunks` doesn't grow unboundedly.
            if _head > 64 && _head * 2 > _chunks.count {
                _chunks.removeFirst(_head)
                _head = 0
            }
        } else {
            _chunks[_head] = front  // persist the advanced readerIndex
        }
        _bufferedBytes -= take
        _position += take
        return slice
    }

    /// Serves suspended readers from buffered data (or `nil` once closed). Collects the
    /// continuations + payloads to resume; the caller resumes them AFTER releasing the lock.
    private func _serviceReaders(_ out: inout [(SuspendedReader, ByteBuffer?)]) {
        while !_readers.isEmpty {
            if let buf = _takeBuffer(upToCount: _readers[0].byteCount) {
                out.append((_readers.removeFirst(), buf))
            } else if _isClosed {
                out.append((_readers.removeFirst(), nil))
            } else {
                break
            }
        }
    }

    /// If buffered data has dropped to/below the low-water mark, collect parked writers to resume.
    private func _resumableWriters(_ out: inout [CheckedContinuation<Void, Error>]) {
        if _bufferedBytes <= lowWaterMark && !_writers.isEmpty {
            out.append(contentsOf: _writers)
            _writers.removeAll()
        }
    }

    // MARK: - Zero-copy fast path (NOT protocol requirements; used by the NIO bridge)

    /// Appends a `ByteBuffer` to the stream with no copy of the producer's bytes (synchronous;
    /// applies no backpressure). Prefer `writeBufferAsync(_:)` on the hot path.
    public func writeBuffer(_ buffer: ByteBuffer) {
        var readersToServe: [(SuspendedReader, ByteBuffer?)] = []
        var writersToResume: [CheckedContinuation<Void, Error>] = []
        lock.lock()
        if !_isClosed && buffer.readableBytes > 0 {
            _chunks.append(buffer)
            _bufferedBytes += buffer.readableBytes
            _writtenBytes += buffer.readableBytes
            _serviceReaders(&readersToServe)
            // Servicing readers may have drained below the low-water mark; wake parked writers.
            _resumableWriters(&writersToResume)
        }
        lock.unlock()
        for (r, buf) in readersToServe { r.continuation.resume(returning: buf) }
        for w in writersToResume { w.resume() }
    }

    /// Appends a `ByteBuffer` to the stream with no copy of the producer's bytes, suspending the
    /// caller for backpressure once buffered data reaches the high-water mark.
    public func writeBufferAsync(_ buffer: ByteBuffer) async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            var readersToServe: [(SuspendedReader, ByteBuffer?)] = []
            var writersToResume: [CheckedContinuation<Void, Error>] = []
            var parked = false
            var thrownError: Error?

            lock.lock()
            if _isClosed {
                thrownError = StreamError.writeToClosedStream("Attempt to write to closed stream")
            } else {
                if buffer.readableBytes > 0 {
                    _chunks.append(buffer)
                    _bufferedBytes += buffer.readableBytes
                    _writtenBytes += buffer.readableBytes
                }
                _serviceReaders(&readersToServe)
                // Wake any *previously* parked writers first (before deciding to park this one),
                // so this writer is never both parked and resumed by its own drain.
                _resumableWriters(&writersToResume)
                if _bufferedBytes >= highWaterMark {
                    _writers.append(cont)  // backpressure: park the producer
                    parked = true
                }
            }
            lock.unlock()

            for (r, buf) in readersToServe { r.continuation.resume(returning: buf) }
            for w in writersToResume { w.resume() }
            if let thrownError {
                cont.resume(throwing: thrownError)
            } else if !parked {
                cont.resume()
            }
        }
    }

    /// Reads up to `count` bytes asynchronously as a `ByteBuffer` slice (zero-copy), suspending
    /// until data is available or the stream closes. Returns `nil` at end of stream.
    public func readBufferAsync(upToCount count: Int) async throws -> ByteBuffer? {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<ByteBuffer?, Error>) in
            var writersToResume: [CheckedContinuation<Void, Error>] = []
            enum Action { case resume(ByteBuffer?); case fail(Error); case suspend }
            var action: Action

            lock.lock()
            if let error = _error {
                _error = nil
                action = .fail(error)
            } else if let buf = _takeBuffer(upToCount: count) {
                _resumableWriters(&writersToResume)
                action = .resume(buf)
            } else if _isClosed {
                action = .resume(nil)
            } else {
                _readers.append(SuspendedReader(continuation: cont, byteCount: count))
                action = .suspend
            }
            lock.unlock()

            for w in writersToResume { w.resume() }
            switch action {
            case .resume(let buf): cont.resume(returning: buf)
            case .fail(let error): cont.resume(throwing: error)
            case .suspend: break  // resumed later by a writer or close
            }
        }
    }

    // MARK: - ReadableStream (Data-returning; one boundary copy for legacy consumers)

    public func read(upToCount count: Int) throws -> Data? {
        var writersToResume: [CheckedContinuation<Void, Error>] = []
        var thrownError: Error?
        var result: Data??

        lock.lock()
        if let error = _error {
            _error = nil
            thrownError = error
        } else if let buf = _takeBuffer(upToCount: count) {
            _resumableWriters(&writersToResume)
            result = .some(Data(buf.readableBytesView))  // single boundary copy
        } else {
            result = .some(_isClosed ? nil : Data())
        }
        lock.unlock()

        for w in writersToResume { w.resume() }
        if let thrownError { throw thrownError }
        return result!
    }

    public func readAsync(upToCount count: Int) async throws -> Data? {
        guard let buf = try await readBufferAsync(upToCount: count) else { return nil }
        return Data(buf.readableBytesView)  // single boundary copy
    }

    public func readToEnd() throws -> Data? {
        var out = Data()
        while let chunk = try read(upToCount: Int.max) {
            if chunk.isEmpty { break }  // open but no data buffered; sync read cannot block
            out.append(chunk)
        }
        return out.isEmpty ? nil : out
    }

    public func readToEndAsync() async throws -> Data? {
        var out = Data()
        while let buf = try await readBufferAsync(upToCount: Int.max) {
            out.append(contentsOf: buf.readableBytesView)
        }
        return out.isEmpty ? nil : out
    }

    // MARK: - WriteableStream (Data-accepting; copies into a ByteBuffer)

    public func write(contentsOf data: Data) throws {
        var readersToServe: [(SuspendedReader, ByteBuffer?)] = []
        var writersToResume: [CheckedContinuation<Void, Error>] = []
        lock.lock()
        do {
            guard !_isClosed else {
                lock.unlock()
                throw StreamError.writeToClosedStream("Attempt to write to closed stream")
            }
        }
        if !data.isEmpty {
            var buffer = allocator.buffer(capacity: data.count)
            buffer.writeBytes(data)
            _chunks.append(buffer)
            _bufferedBytes += data.count
            _writtenBytes += data.count
            _serviceReaders(&readersToServe)
            _resumableWriters(&writersToResume)
        }
        lock.unlock()
        for (r, buf) in readersToServe { r.continuation.resume(returning: buf) }
        for w in writersToResume { w.resume() }
    }

    public func writeAsync(contentsOf data: Data) async throws {
        guard !data.isEmpty else { return }
        var buffer = allocator.buffer(capacity: data.count)
        buffer.writeBytes(data)
        try await writeBufferAsync(buffer)
    }

    // MARK: - Closing

    public func close() { close(error: nil) }

    public func closeWithError(_ error: Error) { close(error: error) }

    private func close(error: Error?) {
        var readersToResume: [(SuspendedReader, ByteBuffer?)] = []
        var readersToFail: [SuspendedReader] = []
        var writersToResume: [CheckedContinuation<Void, Error>] = []

        lock.lock()
        if !_isClosed {
            _isClosed = true
            _length = _writtenBytes
            if let error { _error = error }

            if error != nil {
                // Error close: drain remaining buffered data is moot; fail all waiting readers.
                readersToFail = _readers
                _readers.removeAll()
            } else {
                // Clean close: serve any buffered data to readers, then `nil` to the rest.
                _serviceReaders(&readersToResume)
            }
            // Closed: let any parked writers proceed (their next write throws writeToClosedStream).
            writersToResume = _writers
            _writers.removeAll()
        }
        lock.unlock()

        for (r, buf) in readersToResume { r.continuation.resume(returning: buf) }
        for r in readersToFail { r.continuation.resume(throwing: error!) }
        for w in writersToResume { w.resume() }
    }
}

private extension NSLock {
    func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock(); defer { unlock() }
        return try body()
    }
}

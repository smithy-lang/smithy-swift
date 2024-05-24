//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyStreamsAPI.Stream
import class Foundation.FileHandle
import class Foundation.NSRecursiveLock

/// A `Stream` that wraps a `FileHandle` for reading the file.
///
/// - Note: This class is thread-safe.
public final class FileStream: Stream {

    /// Returns the length of the stream, if known
    public var length: Int? {
        guard let len = try? fileHandle.length() else {
            return nil
        }
        return Int(len)
    }

    let fileHandle: FileHandle

    /// Returns the current position of the stream.
    public var position: Data.Index

    /// Returns true if length is zero, false otherwise.
    public var isEmpty: Bool {
        return length == 0
    }

    /// Returns true if the stream is seekable, false otherwise
    public let isSeekable: Bool = true

    private let lock = NSRecursiveLock()

    /// Initializes a new `FileStream` instance.
    init(fileHandle: FileHandle) {
        self.fileHandle = fileHandle
        self.position = fileHandle.availableData.startIndex
    }

    /// Reads up to `count` bytes from the stream.
    /// - Parameter count: The maximum number of bytes to read.
    /// - Returns: Data read from the stream, or nil if the stream is closed and no data is available.
    public func read(upToCount count: Int) throws -> Data? {
        try lock.withLockingClosure {
            let data: Data?
            if #available(macOS 11, tvOS 13.4, iOS 13.4, watchOS 6.2, *) {
                try fileHandle.seek(toOffset: UInt64(position)) // some bug in fileHandle
                data = try fileHandle.read(upToCount: count)
            } else {
                data = fileHandle.readData(ofLength: count)
            }
            position = position.advanced(by: data?.count ?? 0)
            return data
        }
    }

    public func readAsync(upToCount count: Int) async throws -> Data? {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let data = try read(upToCount: count)
                continuation.resume(returning: data)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Reads all remaining bytes from the stream.
    /// - Returns: Data read from the stream, or nil if the stream is closed and no data is available.
    public func readToEnd() throws -> Data? {
        try lock.withLockingClosure {
            let data: Data?
            if #available(macOS 11, tvOS 13.4, iOS 13.4, watchOS 6.2, *) {
                data = try fileHandle.readToEnd()
            } else {
                data = fileHandle.readDataToEndOfFile()
            }
            position = position.advanced(by: data?.count ?? 0)
            return data
        }
    }

    public func readToEndAsync() async throws -> Data? {
        try await withCheckedThrowingContinuation { continuation in
            do {
                let data = try readToEnd()
                continuation.resume(returning: data)
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    /// Seeks to the specified offset in the stream.
    /// - Parameter offset: The offset to seek to.
    public func seek(toOffset offset: Int) throws {
        try lock.withLockingClosure {
            if #available(macOS 11, tvOS 13.4, iOS 13.4, watchOS 6.2, *) {
                try fileHandle.seek(toOffset: UInt64(offset))
            } else {
                fileHandle.seek(toFileOffset: UInt64(offset))
            }
            position = offset
        }
    }

    /// Writes the specified data to the stream.
    /// - Parameter data: The data to write.
    public func write(contentsOf data: Data) throws {
        try lock.withLockingClosure {
            if #available(macOS 11, tvOS 13.4, iOS 13.4, watchOS 6.2, *) {
                try fileHandle.write(contentsOf: data)
            } else {
                fileHandle.write(data)
            }
        }
    }

    /// Closes the stream.
    public func close() {
       lock.withLockingClosure {
           if #available(macOS 11, tvOS 13.4, iOS 13.4, watchOS 6.2, *) {
               try? fileHandle.close()
           } else {
               fileHandle.closeFile()
           }
        }
    }

    public func closeWithError(_ error: Error) {
        // The error is only relevant when streaming to a programmatic consumer, not to disk.
        // So close the file handle in this case, and the error is dropped.
        close()
    }
}

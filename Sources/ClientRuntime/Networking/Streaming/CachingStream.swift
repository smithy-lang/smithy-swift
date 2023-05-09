//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A stream that caches data read from the base stream.
/// This allows the stream to be read multiple times without having to re-read the data from the base stream.
/// - Note: This is thread-safe.
public class CachingStream: Stream {
    /// Returns the current position in the stream
    public private(set) var position: Data.Index

    /// Returns the length of the stream, if known
    public var length: Int? {
        base.length
    }

    /// Returns true if the base stream is empty, false otherwise
    public var isEmpty: Bool {
        base.isEmpty
    }

    /// Returns true, caching streams are always seekable
    public var isSeekable: Bool = true

    let base: Stream
    public private(set) var cache = Data()

    private let lock = NSRecursiveLock()

    /// Initializes a new `CachingStream` instance.
    /// - Parameter base: The base stream to read from.
    public init(base: Stream) {
        self.base = base
        self.position = base.position
    }

    /// Reads up to `count` bytes from the stream.
    /// Depending on the current position in the stream, this may read from the cache or the base stream.
    /// - Parameter count: The maximum number of bytes to read.
    /// - Returns: Data read from the stream, or nil if the stream is closed and no data is available.
    public func read(upToCount count: Int) throws -> Data? {
        try lock.withLockingClosure {
            var data = Data()
            var remaining = count

            if position < base.position {
                // we've already read this data, so just read it from the cache
                let toRead = min(count, cache.count - position)
                let endPosition = position.advanced(by: toRead)
                data = cache[position..<endPosition]

                remaining -= toRead
            }

            var baseClosed = false
            if remaining > 0 {
                // we haven't read this data yet, so read it from the base stream
                let next = try base.read(upToCount: remaining)
                if let next = next {
                    data.append(next)
                    cache.append(next)
                } else {
                    baseClosed = true
                }
            }

            // update position
            position = position.advanced(by: data.count)

            // if base stream is closed and there's no data left, return nil
            // this will signal the end of the stream
            if baseClosed && data.isEmpty {
                return nil
            }

            return data
        }
    }

    /// Reads all data from the stream.
    /// Depending on the current position in the stream, this may read from the cache or the base stream.
    /// - Returns: Data read from the stream, or nil if the stream is closed and no data is available.
    public func readToEnd() throws -> Data? {
        try lock.withLockingClosure {
            var data = Data()

            if position < base.position {
                // we've already read this data, so just read it from the cache
                data = cache[position...]
            }

            var baseClosed = false
            // we haven't read this data yet, so read it from the base stream
            let next = try base.readToEnd()
            if let next = next {
                data.append(next)
                cache.append(next)
            } else {
                baseClosed = true
            }

            // update position
            position = position.advanced(by: data.count)

            // if base stream is closed and there's no data left, return nil
            // this will signal the end of the stream
            if baseClosed && data.isEmpty {
                return nil
            }

            return data
        }
    }

    /// Seeks to the specified offset in the stream.
    /// - Parameter offset: The offset to seek to.
    public func seek(toOffset offset: Int) throws {
        try lock.withLockingClosure {
            let newPosition = cache.startIndex.advanced(by: offset)

            // make sure the new position is within the bounds of the cache
            guard newPosition >= cache.startIndex && newPosition <= cache.endIndex else {
                throw StreamError.invalidOffset("Invalid offset: \(offset)")
            }

            position = newPosition
        }
    }

    /// Writes the specified data to the stream.
    /// - Parameter data: The data to write.
    public func write(contentsOf data: Data) throws {
        try base.write(contentsOf: data)
    }

    /// Closes the stream.
    public func close() throws {
        try base.close()
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public class CachingStream: Stream {
    public var position: Data.Index

    public var length: Int? {
        base.length
    }

    public var isEmpty: Bool {
        base.isEmpty
    }

    let base: Stream
    var cache = Data()

    let lock = NSLock()

    public init(base: Stream) {
        self.base = base
        self.position = base.position
    }

    public func read(upToCount count: Int) throws -> Data? {
        try lock.withLockingThrowingClosure {
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

    public func readToEnd() throws -> Data? {
        try lock.withLockingThrowingClosure {
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

    public func seek(toOffset offset: Int) throws {
        try lock.withLockingThrowingClosure {
            position = cache.startIndex.advanced(by: offset)
        }
    }

    public func write(contentsOf data: Data) throws {
        try base.write(contentsOf: data)
    }

    public func close() throws {
        try base.close()
    }
}

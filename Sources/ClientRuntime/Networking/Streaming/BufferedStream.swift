//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public class BufferedStream: Stream {
    public var length: Int?

    public var position: Data.Index

    public var isEmpty: Bool {
        return buffer.isEmpty
    }

    var isClosed: Bool

    var buffer = Data()
    let lock = NSLock()

    public init(data: Data = .init(), isClosed: Bool = false) {
        self.buffer = data
        self.position = data.startIndex
        self.length = data.count
        self.isClosed = isClosed
    }

    public func read(upToCount count: Int) throws -> Data? {
        lock.withLockingClosure {
            let toRead = min(count, buffer.count)
            let endPosition = position.advanced(by: toRead)
            let chunk = buffer[position..<endPosition]

            // remove the data we just read
            buffer.removeFirst(toRead)

            // update position
            position = endPosition

            // if we're closed and there's no data left, return nil
            // this will signal the end of the stream
            if isClosed && chunk.isEmpty {
                return nil
            }

            return chunk
        }
    }

    public func readToEnd() throws -> Data? {
        var data = Data()
        
        while let next = try read(upToCount: Int.max) {
            data.append(next)
        }

        return lock.withLockingClosure {
            // if we're closed and there's no data left, return nil
            // this will signal the end of the stream
            if isClosed && data.isEmpty {
                return nil
            }

            return data
        }
    }

    public func seek(toOffset offset: Int) throws {
        lock.withLockingClosure {
            self.position = buffer.startIndex.advanced(by: offset)
        }
    }

    public func write(contentsOf data: Data) throws {
        lock.withLockingClosure {
            // append the data to the buffer
            // this will increase the in-memory size of the buffer
            buffer.append(data)
            length = (length ?? 0) + data.count
        }
    }

    public func close() throws {
        lock.withLockingClosure {
            isClosed = true
        }
    }
}

extension NSLock {
     /// Execute a closure while holding the lock
     /// - Parameter closure: A closure to execute while holding the lock
     /// - Returns: The return value of the closure
     func withLockingClosure<T>(closure: () -> T) -> T {
         lock()
         defer {
             unlock()
         }
         return closure()
     }

     /// Execute a throwing closure while holding the lock
     /// - Parameter closure: A throwing closure to execute while holding the lock
     /// - Returns: The return value of the closure
     func withLockingThrowingClosure<T>(closure: () throws -> T) throws -> T {
         lock()
         defer {
             unlock()
         }
         return try closure()
     }
 }

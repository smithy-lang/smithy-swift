/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import AwsCommonRuntimeKit
import class Foundation.FileHandle
import class Foundation.FileManager

public protocol StreamReader: AnyObject {
    var availableForRead: UInt { get set}
    var hasFinishedWriting: Bool {get set}

    /// Read up to a maximum number of bytes on a stream that is opened..
    /// WARNING:  Be careful as this will read the entire byte stream into memory (up to limit).
    func read(maxBytes: UInt?, rewind: Bool) -> ByteBuffer
    func seek(offset: Int)
    func onError(error: ClientError)
    func write(buffer: ByteBuffer)
}

public class AsyncStreamReader: StreamReader, IStreamable, AsyncSequence {
    public typealias AsyncIterator = Iterator
    public typealias Element = Data
    
    public func makeAsyncIterator() -> Iterator {
        return AsyncIterator(iterator: stream.makeAsyncIterator())
    }

    public struct Iterator: AsyncIteratorProtocol {
        var iterator: AsyncThrowingStream<Data, Error>.Iterator

        init(iterator: AsyncThrowingStream<Data, Error>.Iterator) {
            self.iterator = iterator
        }

        mutating public func next() async throws -> Data? {
            let element = try await iterator.next()
            return element
        }
    }

    public func seek(offset: Int) {
        fatalError()
    }
    
    public var availableForRead: UInt
    
    public var hasFinishedWriting: Bool

    internal let stream: AsyncThrowingStream<Data, Error>

    public init(_ stream: AsyncThrowingStream<Data, Error>) {
        self.stream = stream
        self.availableForRead = 1
        self.hasFinishedWriting = false
    }
    
    public func read(maxBytes: UInt?, rewind: Bool) -> AwsCommonRuntimeKit.ByteBuffer {
        do {
            let result = try _unsafeWait {
                await self.read(maxBytes: maxBytes, rewind: rewind)
            }
            return result
        } catch {
            fatalError()
        }
    }
    
    public func read(maxBytes: UInt?, rewind: Bool) async -> AwsCommonRuntimeKit.ByteBuffer {
        var data = Data()
        var remaining = maxBytes ?? UInt.max
        var iterator = stream.makeAsyncIterator()
        while remaining > 0 {
            do {
                let next = try await iterator.next()
                if let next = next {
                    data.append(next)
                    remaining -= 1
                } else {
                    break
                }
            } catch {
                fatalError()
            }
        }
        return ByteBuffer(data: data)
    }
    
    public func onError(error: ClientError) {
        fatalError()
    }
    
    public func write(buffer: AwsCommonRuntimeKit.ByteBuffer) {
        fatalError()
    }
    
    public func seek(offset: Int64, streamSeekType: AwsCommonRuntimeKit.StreamSeekType) throws {
        switch streamSeekType {
        case .begin:
            break
        case .end:
            break
        }
    }

    public func read(buffer: UnsafeMutableBufferPointer<UInt8>) throws -> Int? {
        let data = self.read(maxBytes: UInt(buffer.count), rewind: false).getData()
        data.copyBytes(to: buffer, count: data.count)
        return data.count
    }
}

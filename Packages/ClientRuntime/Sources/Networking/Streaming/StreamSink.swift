/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import AwsCommonRuntimeKit
import class Foundation.FileHandle
import class Foundation.FileManager

// TODO: handle backpressure more thoroughly to allow for indication that they are ready for more
@available(*, message: "This streaming interface is unstable currently for dynamic streaming")
public protocol StreamSink: AnyObject {
    var availableForRead: Int { get set }
    var isClosedForWrite: Bool {get set}

    ///Read up to limit of bytes into a ByteBuffer until limit is reached or channel is closed.
    ///WARNING:  Be careful as this will potentially read the entire byte stream into memory (up to limit).
    func readRemaining(limit: Int) -> ByteBuffer
    func readFully(sink: inout ByteBuffer, offset: Int, length: Int)
    func readAvailable(sink: inout ByteBuffer, offset: Int, length: Int) -> Int
    func onError(error: ClientError)
    func write(buffer: ByteBuffer)
}

public class DataStreamSink: StreamSink {
    public var availableForRead: Int
    
    public var isClosedForWrite: Bool

    //TODO: should this be a channel of bytes to consume?
    public var data: Data
    public var error: ClientError?

    init(data: Data = Data()) {
        self.data = data
        self.availableForRead = 0
        self.isClosedForWrite = false
    }
    
    public func readRemaining(limit: Int) -> ByteBuffer {
        var buffer = ByteBuffer(size: min(availableForRead, limit))
        let consumed = readAsMuchAsPossible(byteBuffer: &buffer, limit: limit)
        
        if consumed >= limit || availableForRead == 0 {
            return buffer
        } else {
            //TODO: should this be suspending the thread until there is more to read?
            return readRemaining(limit: limit - consumed)
        }
    }
    
    private func readAsMuchAsPossible(byteBuffer: inout ByteBuffer, limit: Int) -> Int {
        var consumed = 0
        var remaining = limit
        
        while availableForRead > 0 && remaining > 0 {
            //TODO: possibly need a hand written channel that we can pull from here
            //TODO: how do we get the next set of bytes asynchronously without holding in memory?
            //TODO: we are putting all the data in at once and not using limit
            byteBuffer.put(data)
            
            consumed += data.count
            remaining = limit - consumed
            markBytesConsumed(size: data.count)
        }
        
        return consumed
    }
    
    private func readAsMuchAsPossible(byteBuffer: inout ByteBuffer, offset: Int, length: Int) -> Int {
        var consumed = 0
        var currentOffset = offset
        var remaining = length
        
        while availableForRead > 0 && remaining > 0 {
            let rc = data.count
            byteBuffer.put(data)
            consumed += rc
            currentOffset += rc
            remaining = length - consumed
            
            markBytesConsumed(size: rc)
        }
        
        return consumed
    }
    
    private func markBytesConsumed(size: Int) {
        availableForRead -= size
    }
    
    public func readFully(sink: inout ByteBuffer, offset: Int, length: Int) {
        let rc = readAsMuchAsPossible(byteBuffer: &sink, offset: offset, length: length)
        if rc < length {
            readFully(sink: &sink, offset: offset + rc, length: length - rc)
        }
    }
    
    public func readAvailable(sink: inout ByteBuffer, offset: Int, length: Int) -> Int {
        let consumed = readAsMuchAsPossible(byteBuffer: &sink, offset: offset, length: length)
        if consumed  == 0 {
            return -1
        } else if consumed > 0 || length == 0 {
            return consumed
        } else {
            return readAvailable(sink: &sink, offset: offset, length: length)
        }
    }
    
    public func write(buffer: ByteBuffer) {
        data.append(buffer.toData())
        availableForRead += Int(buffer.length)
    }
    
    public var contentLength: Int? {
        return data.count
    }

    public func toBytes() -> ByteBuffer {
        return ByteBuffer(data: data)
    }

    public func onError(error: ClientError) {
        self.error = error
    }
}

extension Data {
    func copyBytes<T>(as _: T.Type) -> [T] {
        return withUnsafeBytes { (bytes: UnsafePointer<T>) in
            Array(UnsafeBufferPointer(start: bytes, count: count / MemoryLayout<T>.stride))
        }
    }
}


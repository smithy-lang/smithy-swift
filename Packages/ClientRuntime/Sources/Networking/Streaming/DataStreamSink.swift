//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit

// TODO: handle backpressure more thoroughly to allow for indication that they are ready for more
public class DataStreamSink: StreamSink {
    public var availableForRead: UInt
    
    public var isClosedForWrite: Bool

    //TODO: should this be a channel of bytes to consume?
    public var data: Data
    public var error: ClientError?

    init(data: Data = Data()) {
        self.data = data
        self.availableForRead = 0
        self.isClosedForWrite = false
    }
    
    public func readRemaining(maxBytes: UInt) -> ByteBuffer {
        var buffer = ByteBuffer(size: min(Int(availableForRead), Int(maxBytes)))
        let consumed = readAsMuchAsPossible(byteBuffer: &buffer, maxBytes: maxBytes)
        
        if consumed >= maxBytes || availableForRead == 0 {
            return buffer
        } else {
            //TODO: should this be suspending the thread until there is more to read?
            return readRemaining(maxBytes: maxBytes - consumed)
        }
    }
    
    private func readAsMuchAsPossible(byteBuffer: inout ByteBuffer, maxBytes: UInt) -> UInt {
        var consumed: UInt = 0
        var remaining = maxBytes
        
        while availableForRead > 0 && remaining > 0 {
            //TODO: possibly need a hand written channel that we can pull from here
            //TODO: how do we get the next set of bytes asynchronously without holding in memory?
            //TODO: we are putting all the data in at once and not using limit
            byteBuffer.put(data)
            
            consumed += UInt(data.count)
            remaining = maxBytes - consumed
            markBytesConsumed(size: UInt(data.count))
        }
        
        return consumed
    }
    
    private func readAsMuchAsPossible(byteBuffer: inout ByteBuffer, offset: UInt, length: UInt) -> UInt {
        var consumed: UInt = 0
        var currentOffset = offset
        var remaining = length
        
        while availableForRead > 0 && remaining > 0 {
            let rc = UInt(data.count)
            byteBuffer.put(data)
            consumed += rc
            currentOffset += rc
            remaining = length - consumed
            
            markBytesConsumed(size: rc)
        }
        
        return consumed
    }
    
    private func markBytesConsumed(size: UInt) {
        availableForRead -= size
    }
    
    public func readFully(sink: inout ByteBuffer, offset: UInt, length: UInt) {
        let rc = readAsMuchAsPossible(byteBuffer: &sink, offset: offset, length: length)
        if rc < length {
            readFully(sink: &sink, offset: offset + rc, length: length - rc)
        }
    }
    
    public func readAvailable(sink: inout ByteBuffer, offset: UInt, length: UInt) -> UInt {
        let consumed = readAsMuchAsPossible(byteBuffer: &sink, offset: offset, length: length)
        if consumed == 0 {
            return 0
        } else if consumed > 0 || length == 0 {
            return consumed
        } else {
            return readAvailable(sink: &sink, offset: offset, length: length)
        }
    }
    
    public func write(buffer: ByteBuffer) {
        data.append(buffer.toData())
        availableForRead += UInt(buffer.length)
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

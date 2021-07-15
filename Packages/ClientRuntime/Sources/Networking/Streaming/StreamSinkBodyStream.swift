//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
	

import Foundation
import AwsCommonRuntimeKit
import AwsCIo

class StreamSinkBodyStream: AwsStream {
    var byteBuffer: ByteBuffer
    var status: aws_stream_status {
        return aws_stream_status(is_end_of_stream: streamSink.availableForRead == 0, is_valid: true)
    }
    
    var length: Int64 {
        Int64(streamSink.availableForRead)
    }
    
    private var streamSink: StreamSink
    
    init(streamSink: StreamSink) {
        self.streamSink = streamSink
        self.byteBuffer = ByteBuffer(size: Int(streamSink.availableForRead))
    }
    
    func seek(offset: Int64, basis: aws_stream_seek_basis) -> Bool {
        streamSink.readAvailable(sink: &byteBuffer, offset: UInt(offset), length: UInt(length))
        return true
    }
    
    func read(buffer: inout aws_byte_buf) -> Bool {
        let bufferCapacity = buffer.capacity - buffer.len
        var consumed: UInt = 0
        while(!streamSink.isClosedForWrite) {
            _ = streamSink.byteBuffer.read(buffer: &buffer)
            consumed += streamSink.readAvailable(sink: &byteBuffer, offset: consumed, length: UInt(bufferCapacity))
        }

        return !self.status.is_end_of_stream
    }
}

//extension FileHandle: AwsStream {
//    @inlinable
//    public var status: aws_stream_status {
//        return aws_stream_status(is_end_of_stream: self.length == self.offsetInFile, is_valid: true)
//    }
//
//    @inlinable
//    public var length: Int64 {
//        let savedPos = self.offsetInFile
//        defer { self.seek(toFileOffset: savedPos ) }
//        self.seekToEndOfFile()
//        return Int64(self.offsetInFile)
//    }
//
//    @inlinable
//    public func seek(offset: Int64, basis: aws_stream_seek_basis) -> Bool {
//        let targetOffset: UInt64
//        if basis.rawValue == AWS_SSB_BEGIN.rawValue {
//            targetOffset = self.offsetInFile + UInt64(offset)
//        } else {
//            targetOffset = self.offsetInFile - UInt64(offset)
//        }
//        self.seek(toFileOffset: targetOffset)
//        return true
//    }
//
//    @inlinable
//    public func read(buffer: inout aws_byte_buf) -> Bool {
//        let data = self.readData(ofLength: buffer.capacity - buffer.len)
//        if data.count > 0 {
//            let result = buffer.buffer.advanced(by: buffer.len)
//            data.copyBytes(to: result, count: data.count)
//            buffer.len += data.count
//            return true
//        }
//        return !self.status.is_end_of_stream
//    }
//}

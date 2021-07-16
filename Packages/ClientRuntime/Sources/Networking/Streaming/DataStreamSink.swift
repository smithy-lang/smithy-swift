//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit
import Foundation

public class DataStreamSink: StreamReader {
    public var availableForRead: UInt
    private var _isClosedForWrite: Bool = false
    
    public var isClosedForWrite: Bool {
        get {
            lock.lock()
            defer {
                lock.unlock()
            }
            return _isClosedForWrite
        }
        set {
            withLockingClosure {
                _isClosedForWrite = newValue
            }
        }
    }

    public var byteBuffer: ByteBuffer
    var offset: UInt
    let lock = NSLock()
    public var error: ClientError?

    init(byteBuffer: ByteBuffer = ByteBuffer(size: 0)) {
        self.byteBuffer = byteBuffer
        self.availableForRead = 0
        self.offset = 0
    }
    
    public func read(maxBytes: UInt? = nil) -> ByteBuffer {
        let buffer = ByteBuffer(size: Int(maxBytes ?? availableForRead))
        withLockingClosure {
            buffer.put(byteBuffer, offset: offset, maxBytes: maxBytes)
            availableForRead -= UInt(buffer.length)
            offset += UInt(buffer.length)
        }
        return buffer
    }
    
    public func seek(offset: Int) {
        withLockingClosure {
            let temp = Int(self.offset) + offset
            if temp < 0 {
                self.offset = 0
            } else {
                self.offset = UInt(temp)
            }
        }
    }
    
    public func write(buffer: ByteBuffer) {
        withLockingClosure {
            byteBuffer.put(buffer)
            availableForRead += UInt(buffer.length)
        }
    }
    
    public var contentLength: Int64? {
        lock.lock()
        defer {
            lock.unlock()
        }
        return byteBuffer.length
    }

    public func onError(error: ClientError) {
        withLockingClosure {
            self.error = error
        }
    }
    
    private func withLockingClosure(closure: () -> Void) {
        lock.lock()
        closure()
        lock.unlock()
    }

}




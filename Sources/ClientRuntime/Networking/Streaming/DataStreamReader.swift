//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit
import Foundation

public class DataStreamReader: StreamReader {
    private var _availableForRead: UInt
    
    public var availableForRead: UInt {
        return _availableForRead
    }
    
    private var _hasFinishedWriting: Bool
    
    public var hasFinishedWriting: Bool {
        get {
            withLockingClosure {
                return _hasFinishedWriting
            }
        }
        set {
            withLockingClosure {
                _hasFinishedWriting = newValue
            }
        }
    }

    private var byteBuffer: ByteBuffer
    private var offset: UInt
    private let lock = NSLock()
    private var error: ClientError?

    init(byteBuffer: ByteBuffer = ByteBuffer(size: 0)) {
        self.byteBuffer = byteBuffer
        self._availableForRead = 0
        self.offset = 0
        self._hasFinishedWriting = false
    }
    
    public func read(maxBytes: UInt? = nil, rewind: Bool = false) -> ByteBuffer {
        var data = Data()
        withLockingClosure {
            let count = Int(maxBytes ?? availableForRead)
            let ptr = UnsafeMutablePointer<UInt8>.allocate(capacity: count)
            let buffer = UnsafeMutableBufferPointer(start: ptr, count: count)
            let bytesRead = byteBuffer.read(buffer: buffer)
            data = Data(buffer)
            ptr.deallocate()
                        
            if !rewind, let bytesRead = bytesRead {
                _availableForRead -= UInt(truncatingIfNeeded: bytesRead)
                offset += UInt(truncatingIfNeeded: bytesRead)
            }
        }
        return ByteBuffer(data: data)
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
            let data = byteBuffer.getData() + buffer.getData()
            byteBuffer = ByteBuffer(data: data)
            _availableForRead += UInt(truncatingIfNeeded: buffer.length())
        }
    }
    
    public var contentLength: UInt? {
        withLockingClosure {
            return UInt(truncatingIfNeeded: byteBuffer.length())
        }
    }

    public func onError(error: ClientError) {
        withLockingClosure {
            self.error = error
        }
    }
    
    private func withLockingClosure<T>(closure: () -> T) -> T {
        lock.lock()
        defer {
            lock.unlock()
        }
        return closure()
    }

}

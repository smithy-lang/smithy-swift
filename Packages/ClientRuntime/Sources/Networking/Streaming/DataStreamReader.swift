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
    
    public func read(maxBytes: UInt? = nil) -> ByteBuffer {
        let buffer = ByteBuffer(size: Int(maxBytes ?? availableForRead))
        withLockingClosure {
            buffer.put(byteBuffer, offset: offset, maxBytes: maxBytes)
            _availableForRead -= UInt(buffer.length)
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
            _availableForRead += UInt(buffer.length)
        }
    }
    
    public var contentLength: UInt? {
        withLockingClosure() {
            return byteBuffer.length
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

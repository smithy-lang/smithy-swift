//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCommonRuntimeKit
import Foundation

/// A `StreamReader` that reads from a `ByteBuffer`
/// It allows thread safe reading, writing and seeking
public class DataStreamReader: StreamReader {
    private var _availableForRead: UInt
    public var availableForRead: UInt {
        get {
            lock.withLockingClosure {
                return _availableForRead
            }
        }
        set {
            lock.withLockingClosure {
                _availableForRead = newValue
            }
        }
    }

    private var _hasFinishedWriting: Bool
    public var hasFinishedWriting: Bool {
        get {
            lock.withLockingClosure {
                return _hasFinishedWriting
            }
        }
        set {
            lock.withLockingClosure {
                _hasFinishedWriting = newValue
            }
        }
    }

    internal var byteBuffer: ByteBuffer

    private var offset: UInt
    private let lock = NSLock()
    private var error: ClientError?

    public init(byteBuffer: ByteBuffer = ByteBuffer(size: 0)) {
        self.byteBuffer = byteBuffer
        self._availableForRead = UInt(byteBuffer.length())
        self.offset = 0
        self._hasFinishedWriting = false
    }

    public convenience init(data: Data) {
        self.init(byteBuffer: .init(data: data))
    }

    public func read(maxBytes: UInt? = nil, rewind: Bool = false) -> ByteBuffer {
        let count = maxBytes ?? availableForRead
        var data = Data(count: Int(count))
        lock.withLockingClosure {
            var bytesRead: Int?
            data.withUnsafeMutableBytes { buffer in
                let typedBuffer = buffer.bindMemory(to: UInt8.self)
                bytesRead = byteBuffer.read(buffer: typedBuffer)
            }

            if !rewind, let bytesRead = bytesRead {
                _availableForRead -= UInt(bytesRead)
                offset += UInt(bytesRead)
            }

            if let bytesRead = bytesRead {
                data = data.prefix(bytesRead)
            } else {
                data = .init()
            }
        }
        return ByteBuffer(data: data)
    }
    
    public func read(upToCount count: Int?) async throws -> Data? {
        return read(maxBytes: UInt(count ?? Int.max), rewind: false).getData()
    }

    public func seek(offset: Int) throws {
        try lock.withLockingThrowingClosure {
            try byteBuffer.seek(offset: Int64(offset), streamSeekType: .begin)
            _availableForRead = UInt(Int(byteBuffer.length()) - offset)
        }
    }

    public func write(buffer: ByteBuffer) {
        lock.withLockingClosure {
            let data = byteBuffer.getData() + buffer.getData()
            byteBuffer = ByteBuffer(data: data)
            _availableForRead += UInt(buffer.length())
        }
    }

    public var contentLength: UInt? {
        lock.withLockingClosure {
            return UInt(byteBuffer.length())
        }
    }

    public func onError(error: ClientError) {
        lock.withLockingClosure {
            self.error = error
        }
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AwsCommonRuntimeKit

/// A `StreamReader` that reads `AsyncThrowingStream<Data, Error>`
/// Event Stream messages are sent as a series of `Data` chunks
public class AsyncThrowingStreamReader: StreamReader {
    public var availableForRead: UInt {
        get {
            fatalError("availableForRead is not supported with async streams")
        }
        set {
            fatalError("availableForRead is not supported with async streams")
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

    internal let stream: AsyncThrowingStream<Data, Error>
    private let lock = NSLock()

    public init(stream: AsyncThrowingStream<Data, Error>) {
        self.stream = stream
        self._hasFinishedWriting = false
    }

    /// This method is not supported with async streams
    /// - Parameter maxBytes: not used
    /// - Parameter rewind: not used
    /// - Returns: `ByteBuffer` with size 0
    public func read(maxBytes: UInt?, rewind: Bool = false) -> AwsCommonRuntimeKit.ByteBuffer {
        return .init(size: 0)
    }

    /// Reads number of bytes that are available for reading from the stream
    /// This behavior allows to send a message as soon as it is available without
    /// buffering the number of requested bytes.
    /// - Parameter count: not used
    /// - Returns: `Data` or `nil` if the stream has finished writing
    public func read(upToCount count: Int?) async throws -> Data? {
        var iterator = stream.makeAsyncIterator()
        do {
            guard let next = try await iterator.next() else {
                _hasFinishedWriting = true
                return nil
            }

            return next
        } catch {
            _hasFinishedWriting = true
            return nil
        }
    }

    public func seek(offset: Int) throws {
        fatalError("Seek is not supported with async streams")
    }

    public func onError(error: ClientError) {
        fatalError("onError is not supported with async streams")
    }

    public func write(buffer: AwsCommonRuntimeKit.ByteBuffer) {
        fatalError("write is not supported with async streams")
    }
}

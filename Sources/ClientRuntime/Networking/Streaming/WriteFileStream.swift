//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// A `Stream` that wraps a `FileHandle`.
/// - Note: This class is thread-safe.
final class WriteFileStream: WriteableStream {
    /// Returns the length of the stream, if known
    var length: Int? {
        guard let len = try? fileHandle.length() else {
            return nil
        }
        return Int(len)
    }

    let fileHandle: FileHandle

    /// Returns the current position of the stream.
    var position: Data.Index

    /// Returns true if length is zero, false otherwise.
    var isEmpty: Bool {
        return length == 0
    }

    /// Returns true if the stream is seekable, false otherwise
    let isSeekable: Bool = true

    private let lock = NSRecursiveLock()

    /// Initializes a new `FileStream` instance.
    init(fileHandle: FileHandle) {
        self.fileHandle = fileHandle
        self.position = fileHandle.availableData.startIndex
    }

    /// Writes the specified data to the stream.
    /// - Parameter data: The data to write.
    func write(contentsOf data: Data) throws {
        try lock.withLockingClosure {
            if #available(macOS 11, tvOS 13.4, iOS 13.4, watchOS 6.2, *) {
                try fileHandle.write(contentsOf: data)
            } else {
                fileHandle.write(data)
            }
        }
    }

    /// Closes the stream.
    func close() {
       lock.withLockingClosure {
           if #available(macOS 11, tvOS 13.4, iOS 13.4, watchOS 6.2, *) {
               try? fileHandle.close()
           } else {
               fileHandle.closeFile()
           }
        }
    }

    func closeWithError(_ error: Error) {
        close()
    }
}

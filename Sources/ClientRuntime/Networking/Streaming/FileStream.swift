//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class FileStream: Stream {
    public var length: Int? {
        guard let len = try? fileHandle.length() else {
            return nil
        }
        return Int(len)
    }

    let fileHandle: FileHandle
    var position: Data.Index
    var isEmpty: Bool {
        return length == 0
    }

    let lock = NSLock()

    init(fileHandle: FileHandle) {
        self.fileHandle = fileHandle
        self.position = fileHandle.availableData.startIndex
    }

    func read(upToCount count: Int) throws -> Data? {
        try lock.withLockingThrowingClosure {
            let data: Data?
            if #available(macOS 11, tvOS 13.4, iOS 13.4, watchOS 6.2, *) {
                data = try fileHandle.read(upToCount: count)
            } else {
                data = fileHandle.readData(ofLength: count)
            }
            position = position.advanced(by: data?.count ?? 0)
            return data
        }
    }

    func readToEnd() throws -> Data? {
        try lock.withLockingThrowingClosure {
            let data: Data?
            if #available(macOS 11, tvOS 13.4, iOS 13.4, watchOS 6.2, *) {
                data = try fileHandle.readToEnd()
            } else {
                data = fileHandle.readDataToEndOfFile()
            }
            position = position.advanced(by: data?.count ?? 0)
            return data
        }
    }

    func seek(toOffset offset: Int) throws {
        try lock.withLockingThrowingClosure {
            if #available(macOS 11, tvOS 13.4, iOS 13.4, watchOS 6.2, *) {
                try fileHandle.seek(toOffset: UInt64(offset))
            } else {
                fileHandle.seek(toFileOffset: UInt64(offset))
            }
            position = offset
        }
    }

    func write(contentsOf data: Data) throws {
        try lock.withLockingThrowingClosure {
            if #available(macOS 11, tvOS 13.4, iOS 13.4, watchOS 6.2, *) {
                try fileHandle.write(contentsOf: data)
            } else {
                fileHandle.write(data)
            }
        }
    }

    func close() throws {
       try lock.withLockingThrowingClosure {
           if #available(macOS 11, tvOS 13.4, iOS 13.4, watchOS 6.2, *) {
               try fileHandle.close()
           } else {
               fileHandle.closeFile()
           }
        }
    }
}

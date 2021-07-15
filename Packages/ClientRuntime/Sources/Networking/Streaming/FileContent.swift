//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit
import class Foundation.FileHandle

public struct FileContent {
    public var contentLength: Int64? {
        return Int64(fileHandle.length)
    }
    
    public func toBytes() -> ByteBuffer {
        return ByteBuffer(data: fileHandle.readDataToEndOfFile())
    }
    
    private let fileHandle: FileHandle
    public init(fileHandle: FileHandle) {
        self.fileHandle = fileHandle
    }
    
    public init(path: String) {
        self.fileHandle = FileHandle(forReadingAtPath: path) ?? FileHandle(fileDescriptor: path.toInt32())
    }
}


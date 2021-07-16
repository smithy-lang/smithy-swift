//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit
import class Foundation.FileHandle

extension FileHandle {
    static func toByteBuffer(path: String) -> ByteBuffer {
        let fileHandle = FileHandle(forReadingAtPath: path) ?? FileHandle(fileDescriptor: path.toInt32())
        return ByteBuffer(data: fileHandle.readDataToEndOfFile())
    }
    
    func toByteBuffer() -> ByteBuffer {
        return ByteBuffer(data: self.readDataToEndOfFile())
    }
}

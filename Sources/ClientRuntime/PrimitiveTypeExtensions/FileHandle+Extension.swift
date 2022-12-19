//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import AwsCommonRuntimeKit
import class Foundation.FileHandle

extension FileHandle {
    
    func toByteBuffer() -> ByteBuffer {
        return ByteBuffer(data: self.readDataToEndOfFile())
    }
}

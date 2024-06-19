//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.ByteStream
import class SmithyStreams.FileStream
import class Foundation.FileHandle

extension ByteStream {

    /// Returns ByteStream from a FileHandle object.
    /// - Parameter fileHandle: FileHandle object to be converted to ByteStream.
    /// - Returns: ByteStream representation of the FileHandle object.
    public static func from(fileHandle: FileHandle) -> ByteStream {
        return .stream(FileStream(fileHandle: fileHandle))
    }
}

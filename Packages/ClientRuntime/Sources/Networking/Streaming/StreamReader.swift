/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import AwsCommonRuntimeKit
import class Foundation.FileHandle
import class Foundation.FileManager

public protocol StreamReader: AnyObject {
    var byteBuffer: ByteBuffer { get set}
    var availableForRead: UInt { get set }
    var isClosedForWrite: Bool {get set}

    ///Read up to a maximum number of bytes on a stream that is opened..
    ///WARNING:  Be careful as this will read the entire byte stream into memory (up to limit).
    func read(maxBytes: UInt?) -> ByteBuffer
    func seek(offset: Int)
    func onError(error: ClientError)
    func write(buffer: ByteBuffer)
}

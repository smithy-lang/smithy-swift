/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import AwsCommonRuntimeKit
import class Foundation.FileHandle
import class Foundation.FileManager

// TODO: handle backpressure more thoroughly to allow for indication that they are ready for more
@available(*, message: "This streaming interface is unstable currently for dynamic streaming")
public protocol StreamSink: AnyObject {
    var byteBuffer: ByteBuffer { get set}
    var availableForRead: UInt { get set }
    var isClosedForWrite: Bool {get set}

    ///Read up to a maximum number of bytes on a stream that is opened..
    ///WARNING:  Be careful as this will read the entire byte stream into memory (up to limit).
    func readRemaining(maxBytes: UInt) -> ByteBuffer
    func readFully(sink: inout ByteBuffer, offset: UInt, length: UInt)
    func readAvailable(sink: inout ByteBuffer, offset: UInt, length: UInt) -> UInt
    func onError(error: ClientError)
    func write(buffer: ByteBuffer)
}

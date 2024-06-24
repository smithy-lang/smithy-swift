//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol Smithy.Stream

/*
 * Default chunk size
 */
public let CHUNK_SIZE_BYTES: Int = 65_536

/*
 * The minimum size of a streaming body before the SDK will chunk 
 * (such as setting aws-chunked content encoding)
 */
public let CHUNKED_THRESHOLD = CHUNK_SIZE_BYTES * 16

public extension Stream {
    /*
     * Return a Bool representing if the ByteStream (request body) is large enough to send in chunks
     */
    var isEligibleForChunkedStreaming: Bool {
        if let length = self.length, length >= CHUNKED_THRESHOLD {
            return true
        } else {
            return false
        }
    }
}

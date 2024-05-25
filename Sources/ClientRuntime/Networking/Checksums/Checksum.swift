//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import AwsCommonRuntimeKit

/**
 * An object that provides a checksum of data provided in chunks to `update`.
 * The checksum may be performed incrementally as chunks are received or all
 * at once when the checksum is finalized, depending on the underlying
 * implementation.
 *
 * It's recommended to compute checksum incrementally to avoid reading the
 * entire payload in memory.
 */
public protocol Checksum {
    // Name of the checksum as a string.
    var checksumName: String { get }

    // Constant length of the digest created by the algorithm in bytes.
    var digestLength: Int { get }

    // Returns the digest of all of the data passed.
    func digest() throws -> HashResult

    /*
     * Adds a chunk of data for which checksum needs to be computed.
     * This can be called many times with new data as it is streamed.
     */
    func update(chunk: Data) throws

    // Resets the checksum to its initial value.
    func reset()

    /*
     * Creates a new checksum object that contains a deep copy of the internal
     * state of the current `Checksum` object.
     */
    func copy() -> any Checksum
}

public enum HashResult {
    case data(Data)
    case integer(UInt32)
}

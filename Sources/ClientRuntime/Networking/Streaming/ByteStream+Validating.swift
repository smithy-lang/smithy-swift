//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.ByteStream
import protocol Smithy.Stream
import class SmithyChecksums.ValidatingBufferedStream
import enum SmithyChecksumsAPI.ChecksumAlgorithm
import class SmithyStreams.BufferedStream

extension ByteStream {

    // Convert the body stream to a ValidatingFileStream to check checksums
    public static func getChecksumValidatingBody(
        stream: Stream,
        expectedChecksum: String,
        checksumAlgorithm: ChecksumAlgorithm
    ) -> ByteStream {
        if let bufferedStream = stream as? BufferedStream {
            return ByteStream.stream(
                ValidatingBufferedStream(
                    stream: bufferedStream,
                    expectedChecksum: expectedChecksum,
                    checksumAlgorithm: checksumAlgorithm
                )
            )
        }
        return ByteStream.stream(stream)
    }
}

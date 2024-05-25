//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyStreamsAPI.Stream
import enum SmithyStreamsAPI.ByteStream

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

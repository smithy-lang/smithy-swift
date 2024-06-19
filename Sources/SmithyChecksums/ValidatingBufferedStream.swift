//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol Smithy.Stream
import protocol SmithyChecksumsAPI.Checksum
import enum SmithyChecksumsAPI.ChecksumAlgorithm
import struct Foundation.Data
import AwsCommonRuntimeKit
import class SmithyStreams.BufferedStream

public class ValidatingBufferedStream {
    private var stream: BufferedStream
    private var checksumAlgorithm: ChecksumAlgorithm
    private var checksum: (any Checksum)
    private var expectedChecksum: String
    private var currentHash: UInt32 = 0

    public init(stream: BufferedStream, expectedChecksum: String, checksumAlgorithm: ChecksumAlgorithm) {
        self.stream = stream
        self.expectedChecksum = expectedChecksum
        self.checksumAlgorithm = checksumAlgorithm
        self.checksum = checksumAlgorithm.createChecksum()
    }
}

extension ValidatingBufferedStream: Stream {

    public var position: Data.Index {
        self.stream.position
    }

    public var length: Int? {
        self.stream.length
    }

    public var isEmpty: Bool {
        self.stream.isEmpty
    }

    public var isSeekable: Bool {
        self.stream.isSeekable
    }

    public func read(upToCount count: Int) throws -> Data? {
        try self.stream.read(upToCount: count)
    }

    public func readAsync(upToCount count: Int) async throws -> Data? {
        try await self.stream.readAsync(upToCount: count)
    }

    public func readToEnd() throws -> Data? {
        try self.stream.readToEnd()
    }

    public func readToEndAsync() async throws -> Data? {
        let streamData = try await self.stream.readToEndAsync()

        // This will be invoked when the user executes the readData() method on ByteStream
        if let data = streamData {
            // Pass chunk data to checksum
            try self.checksum.update(chunk: data)

            if self.position == self.length {
                // Validate and throw
                let actualChecksum = try self.checksum.digest().toBase64String()
                if expectedChecksum != actualChecksum {
                    throw ChecksumMismatchException.message(
                        "Checksum mismatch. Expected \(expectedChecksum) but was \(actualChecksum)"
                    )
                }
            }
        }
        return streamData
    }

    public func write(contentsOf data: Data) throws {
        try self.stream.write(contentsOf: data)
    }

    public func close() {
        self.stream.close()
    }

    public func closeWithError(_ error: Error) {
        self.stream.closeWithError(error)
    }

}

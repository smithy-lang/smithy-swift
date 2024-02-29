//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCommonRuntimeKit

class ValidatingBufferedStream {
    private var stream: BufferedStream
    private var checksum: ChecksumAlgorithm
    private var checksumHash: Hash?
    private var expectedChecksum: String
    private var currentHash: UInt32 = 0

    init(stream: BufferedStream, expectedChecksum: String, checksum: ChecksumAlgorithm) {
        self.stream = stream
        self.expectedChecksum = expectedChecksum
        self.checksum = checksum
        self.checksumHash = checksum.createHash()
    }
}

extension ValidatingBufferedStream: Stream {

    var position: Data.Index {
        self.stream.position
    }

    var length: Int? {
        self.stream.length
    }

    var isEmpty: Bool {
        self.stream.isEmpty
    }

    var isSeekable: Bool {
        self.stream.isSeekable
    }

    func read(upToCount count: Int) throws -> Data? {
        try self.stream.read(upToCount: count)
    }

    func readAsync(upToCount count: Int) async throws -> Data? {
        try await self.stream.readAsync(upToCount: count)
    }

    func readToEnd() throws -> Data? {
        try self.stream.readToEnd()
    }

    func readToEndAsync() async throws -> Data? {
        let streamData = try await self.stream.readToEndAsync()

        // This will be invoked when the user executes the readData() method on ByteStream
        if let data = streamData {
            if let shaHash = checksumHash {
                try shaHash.update(data: data)
            } else {
                let hashResult = try self.checksum.computeHash(of: data, previousHash: self.currentHash)
                if case let .integer(newHash) = hashResult {
                    self.currentHash = newHash
                } else {
                    throw ClientError.unknownError("Checksum result didnt return an integer!")
                }
            }

            if self.position == self.length {
                // Validate and throw
                let actualChecksum: String
                if let shaHash = checksumHash {
                    let hashResult = try HashResult.data(shaHash.finalize())
                    actualChecksum = hashResult.toBase64String()
                } else {
                    actualChecksum = currentHash.toBase64EncodedString()
                }

                if expectedChecksum != actualChecksum {
                    throw ChecksumMismatchException.message(
                        "Checksum mismatch. Expected \(expectedChecksum) but was \(actualChecksum)"
                    )
                }
            }
        }
        return streamData
    }

    func write(contentsOf data: Data) throws {
        try self.stream.write(contentsOf: data)
    }

    func close() {
        self.stream.close()
    }

    func closeWithError(_ error: Error) {
        self.stream.closeWithError(error)
    }

}

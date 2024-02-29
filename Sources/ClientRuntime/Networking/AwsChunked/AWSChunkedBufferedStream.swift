//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCommonRuntimeKit

class AWSChunkedBufferedStream {
    private var stream: BufferedStream
    private var signingConfig: SigningConfig
    private var previousSignature: String
    private var trailingHeaders: Headers
    private var chunkedReader: AWSChunkedReader

    init(
        stream: BufferedStream,
        signingConfig: SigningConfig,
        previousSignature: String,
        trailingHeaders: Headers,
        checksumAlgorithm: ChecksumAlgorithm? = nil
    ) {
        self.stream = stream
        self.signingConfig = signingConfig
        self.previousSignature = previousSignature
        self.trailingHeaders = trailingHeaders

        self.chunkedReader = AWSChunkedReader(
            stream: self.stream,
            signingConfig: self.signingConfig,
            previousSignature: self.previousSignature,
            trailingHeaders: self.trailingHeaders,
            checksum: checksumAlgorithm
        )
    }
}

extension AWSChunkedBufferedStream: Stream {

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
        try await self.stream.readToEndAsync()
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

extension AWSChunkedBufferedStream: AWSChunkedStream {

    func getChunkedReader() -> AWSChunkedReader {
        return self.chunkedReader
    }

    var checksumAlgorithm: ChecksumAlgorithm? {
        get {
            return self.chunkedReader.getChecksumAlgorithm()
        }
        set {
            self.chunkedReader.setChecksumAlgorithm(checksum: newValue)
        }
    }
}

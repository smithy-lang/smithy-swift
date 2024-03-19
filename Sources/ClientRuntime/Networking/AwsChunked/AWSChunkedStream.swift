//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCommonRuntimeKit

/// Reads data from the input stream, chunks it, and passes it out through its output stream.
class AWSChunkedStream {
    private var inputStream: Stream
    private var signingConfig: SigningConfig
    private var previousSignature: String
    private var trailingHeaders: Headers
    private var chunkedReader: AWSChunkedReader
    private var outputStream = BufferedStream()
    private var hasMoreChunks = true

    init(
        inputStream: Stream,
        signingConfig: SigningConfig,
        previousSignature: String,
        trailingHeaders: Headers,
        checksumAlgorithm: ChecksumAlgorithm? = nil
    ) {
        self.inputStream = inputStream
        self.signingConfig = signingConfig
        self.previousSignature = previousSignature
        self.trailingHeaders = trailingHeaders
        self.chunkedReader = AWSChunkedReader(
            stream: self.inputStream,
            signingConfig: self.signingConfig,
            previousSignature: self.previousSignature,
            trailingHeaders: self.trailingHeaders,
            checksum: checksumAlgorithm
        )
    }
}

extension AWSChunkedStream: Stream {

    /// Writes data to the input stream.
    /// - Parameter data: The data to be written.
    func write(contentsOf data: Data) throws {
        try inputStream.write(contentsOf: data)
    }

    /// Closes the input stream.
    ///
    /// The output stream will close once the input stream closes, and all data from the
    /// input stream has been chunked.
    func close() {
        inputStream.close()
    }

    func closeWithError(_ error: any Error) {
        inputStream.closeWithError(error)
    }

    var position: Data.Index {
        self.inputStream.position
    }

    /// Returns the length of the _input_ stream.
    var length: Int? {
        self.inputStream.length
    }

    var isEmpty: Bool {
        self.inputStream.isEmpty
    }

    var isSeekable: Bool {
        self.outputStream.isSeekable
    }

    func read(upToCount count: Int) throws -> Data? {
        try outputStream.read(upToCount: count)
    }

    func readAsync(upToCount count: Int) async throws -> Data? {
        while hasMoreChunks {
            // Process the first chunk and determine if there are more to send
            hasMoreChunks = try await chunkedReader.processNextChunk()

            if !hasMoreChunks {
                // Send the final chunk
                let finalChunk = try await chunkedReader.getFinalChunk()
                try outputStream.write(contentsOf: finalChunk)
                outputStream.close()
            } else {
                let currentChunkBody = chunkedReader.getCurrentChunkBody()
                if !currentChunkBody.isEmpty {
                    try outputStream.write(contentsOf: chunkedReader.getCurrentChunk())
                }
            }
        }
        return try await self.outputStream.readAsync(upToCount: count)
    }

    func readToEnd() throws -> Data? {
        try self.outputStream.readToEnd()
    }

    func readToEndAsync() async throws -> Data? {
        try await self.outputStream.readToEndAsync()
    }

    func seek(toOffset offset: Int) throws {
        try self.outputStream.seek(toOffset: offset)
    }
}

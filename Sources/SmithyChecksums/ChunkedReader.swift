//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyChecksumsAPI.Checksum
import enum SmithyChecksumsAPI.ChecksumAlgorithm
import struct SmithyHTTPAPI.Headers
import AwsCommonRuntimeKit
import SmithyHTTPClient
import struct Foundation.Data
import Smithy

public class ChunkedReader {
    private var stream: ReadableStream
    private var signingConfig: SigningConfig
    private var previousSignature: String
    private var trailingHeaders: Headers
    private var hasLastChunkBeenSent = false
    private var chunk = Data()
    private var chunkBody = Data()
    private var currentHash: UInt32 = 0
    private var emptyChunkSigned = false
    private var checksumAlgorithm: ChecksumAlgorithm?
    private var checksum: (any Checksum)?
    private var checksumString: String?
    private let context: Smithy.Context
    private let cachedChecksum: String?

    init(
        stream: ReadableStream,
        signingConfig: SigningConfig,
        previousSignature: String,
        trailingHeaders: Headers,
        checksumString: String? = nil, // if nil, chunked encoding without checksum
        context: Smithy.Context
    ) throws {
        self.stream = stream
        self.signingConfig = signingConfig
        self.previousSignature = previousSignature
        self.trailingHeaders = trailingHeaders
        self.checksumString = checksumString

        // Determine the checksum algorithm, if provided
        let checksumAlgorithm: ChecksumAlgorithm?
        if let checksumString = checksumString {
            checksumAlgorithm = ChecksumAlgorithm.from(string: checksumString)

            // Unsupported checksum
            if checksumAlgorithm == nil {
                throw UnknownChecksumError.notSupported(checksum: checksumString)
            }
        } else {
            checksumAlgorithm = nil
        }
        self.context = context
        self.cachedChecksum = context.get(key: AttributeKey<String>(name: "ChunkedStreamCachedChecksum"))
        self.checksumAlgorithm = checksumAlgorithm // Enum for working with the checksum
        self.checksum = self.checksumAlgorithm?.createChecksum() // Create an instance of the Checksum
    }

    public func processNextChunk() async throws -> Bool {

        // Check if there are no more chunks to process
        guard !hasLastChunkBeenSent else {
          return false // No more chunks to process
        }

        let nextChunk = try await fetchNextChunk()

        if let chunk = nextChunk {
            if let checksum = self.checksum, cachedChecksum == nil {
                try checksum.update(chunk: self.chunkBody)
            }
            self.chunk = chunk // Store the current chunk
            return true // Chunk processed successfully
        } else {
            hasLastChunkBeenSent = true
            return false // End of the stream
        }
    }

    public func getFinalChunk() async throws -> Data {

        var finalChunk = self.getCurrentChunk() // should be empty

        // Add a checksum if it is not nil
        if let checksum = self.checksum {
            let headerName = "x-amz-checksum-\(checksum.checksumName)"
            let hashResult: String!
            // Use cached checksum from previous attempt if present.
            // Allows request to fail if file payload has changed between retries, increasing durability for S3.
            if let cachedChecksum {
                hashResult = cachedChecksum
            } else {
                hashResult = try checksum.digest().toBase64String()
                context.set(key: AttributeKey<String>(name: "ChunkedStreamCachedChecksum"), value: hashResult)
            }
            self.updateTrailingHeader(name: headerName, value: hashResult)
        }

        // + any trailers
        if !trailingHeaders.headers.isEmpty {
            let trailingHeaderChunk = try await getTrailingHeadersChunk(trailingHeaders: trailingHeaders)
            finalChunk.append(trailingHeaderChunk)
        }

        // Append terminating CRLF to signal end of chunk
        finalChunk.append(Data("\r\n".utf8))

        return finalChunk
    }

    private func fetchNextChunk() async throws -> Data? {
        // Fetch a chunk based on signing configuration
        signingConfig.isUnsigned
            ? try await getUnsignedChunk(from: stream)
            : try await getSignedChunk(from: stream)
    }

    private func getUnsignedChunk(from stream: ReadableStream) async throws -> Data? {
        let chunk = try await stream.readAsync(upToCount: CHUNK_SIZE_BYTES) ?? Data()

        self.chunkBody = chunk

        return constructChunk(chunk: chunk, signature: nil)
    }

    public func getSignedChunk(from stream: ReadableStream) async throws -> Data? {
        let chunk = try await stream.readAsync(upToCount: CHUNK_SIZE_BYTES) ?? Data()

        // keep track of the chunk body without additional structure like chunk-signature
        self.chunkBody = chunk

        // Early exit for empty chunk when already signed
        if chunk.isEmpty && emptyChunkSigned {
            return nil
        }

        // Get signed chunk
        let chunkSigningConfig = signingConfig.toChunkSigningConfig()
        let chunkSignature = try await signChunk(chunk: chunk, config: chunkSigningConfig)
        self.previousSignature = chunkSignature

        return constructChunk(chunk: chunk, signature: chunkSignature)
    }

    private func signChunk(chunk: Data, config: SigningConfig) async throws -> String {
        let chunkSignature = try await AwsCommonRuntimeKit.Signer.signChunk(
            chunk: chunk,
            previousSignature: self.previousSignature,
            config: config
        )
        if chunk.isEmpty {
            // Ensure an empty chunk is only signed once
            emptyChunkSigned = true
        }

        return chunkSignature
    }

    private func constructChunk(chunk: Data, signature: String?) -> Data {
        var signedChunk = Data()

        // Initialize the header with the chunk size.
        var header = "\(chunk.count.hexString)"

        // Conditionally append the chunk-signature if a signature is provided.
        if let signature = signature {
            header += ";chunk-signature=\(signature)"
        }

        // Append the header and CRLF to the signedChunk.
        signedChunk.append(Data("\(header)\r\n".utf8))

        // Append the chunk body and terminating CRLF if not empty.
        if !chunk.isEmpty {
            signedChunk.append(chunk)
            signedChunk.append(Data("\r\n".utf8))
        }

        return signedChunk
    }

    private func getTrailingHeadersChunk(trailingHeaders: Headers) async throws -> Data {

        var trailerBody = Data()

        // Construct the headers string
        let headersString = getTrailingHeadersString(trailingHeaders: trailingHeaders)
        trailerBody.append(contentsOf: headersString.utf8)

        // If not unsigned, sign the trailers and append the signature
        if !signingConfig.isUnsigned {
            let trailerSignature = try await signTrailers(trailingHeaders: trailingHeaders)
            trailerBody.append(Data("x-amz-trailer-signature:\(trailerSignature)\r\n".utf8))
        }

        return trailerBody
    }

    private func signTrailers(trailingHeaders: Headers) async throws -> String {
        let crtTrailerSignerConfig = signingConfig.toTrailingHeadersSigningConfig()
        let trailerSignature = try await AwsCommonRuntimeKit.Signer.signTrailerHeaders(
            headers: trailingHeaders.toHttpHeaders(),
            previousSignature: previousSignature,
            config: crtTrailerSignerConfig
        )
        self.previousSignature = trailerSignature

        return trailerSignature
    }

    private func getTrailingHeadersString(trailingHeaders: Headers) -> String {
        return trailingHeaders.headers.flatMap { header in
            header.value.map { "\(header.name): \($0)\r\n" }
        }.joined()
    }
}

extension ChunkedReader {

    public func updateTrailingHeader(name: String, value: String) {
        self.trailingHeaders.update(name: name, value: value)
    }

    public func getTrailingHeaders() -> Headers {
        return self.trailingHeaders
    }

    public func getChecksumAlgorithm() -> ChecksumAlgorithm? {
        return self.checksumAlgorithm
    }

    public func setChecksumAlgorithm(checksumAlgorithm: ChecksumAlgorithm?) {
        self.checksumAlgorithm = checksumAlgorithm
        self.checksum = checksumAlgorithm?.createChecksum()
    }

    public func getChecksum() -> (any Checksum)? {
        return self.checksum
    }

    public func getCurrentChunk() -> Data {
        return self.chunk
    }

    public func setCurrentChunk(chunk: Data) {
        self.chunk = chunk
    }

    public func getCurrentChunkBody() -> Data {
        return self.chunkBody
    }

    public func setCurrentChunkBody(chunk: Data) {
        self.chunkBody = chunk
    }
}

extension Int {
    var hexString: String {
        return String(self, radix: 16)
    }
}

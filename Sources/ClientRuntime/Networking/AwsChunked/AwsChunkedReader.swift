//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCommonRuntimeKit

public class AwsChunkedReader {
    private var stream: Stream
    private var signingConfig: SigningConfig
    private var previousSignature: String
    private var trailingHeaders: Headers
    private var hasLastChunkBeenSent = false
    private var chunk = Data()
    private var chunkBody = Data()
    private var currentHash: UInt32 = 0
    private var emptyChunkSigned = false
    private var checksum: HashFunction?
    private var checksumHash: Hash?

    init(
        stream: Stream,
        signingConfig: SigningConfig,
        previousSignature: String,
        trailingHeaders: Headers,
        checksum: HashFunction? = nil // if nil, chunked encoding without checksum
    ) {
        self.stream = stream
        self.signingConfig = signingConfig
        self.previousSignature = previousSignature
        self.trailingHeaders = trailingHeaders
        self.checksum = checksum
        self.checksumHash = checksum?.createHash() // for supporting data-based checksums
    }

    public func processNextChunk() async throws -> Bool {

        // Check if there are no more chunks to process
        if hasLastChunkBeenSent {
          return false // No more chunks to process
        }

        let nextChunk = try await fetchNextChunk()

        if let chunk = nextChunk {
            if let checksum = self.checksum {
                try self.hashChunk(checksumAlgorithm: checksum)
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
        if let checksumAlgorithm = self.checksum {
            let headerName = "x-amz-checksum-\(checksumAlgorithm)"
            if let shaHash = checksumHash {
                let hashResult = try HashResult.data(shaHash.finalize())
                self.updateTrailingHeader(name: headerName, value: hashResult.toBase64String())
            } else {
                self.updateTrailingHeader(name: headerName, value: self.currentHash.toBase64EncodedString())
            }

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

    private func hashChunk(checksumAlgorithm: HashFunction) throws {
        if let shaHash = checksumHash {
            try shaHash.update(data: self.chunkBody)
        } else {
            let hashResult = try checksumAlgorithm.computeHash(of: self.chunkBody, previousHash: self.currentHash)
            if case let .integer(newHash) = hashResult {
                currentHash = newHash
            } else {
                throw ClientError.unknownError("Checksum result didnt return an integer!")
            }
        }
    }

    private func fetchNextChunk() async throws -> Data? {
        // Fetch a chunk based on signing configuration
        signingConfig.isUnsigned
            ? try await getUnsignedChunk(from: stream)
            : try await getSignedChunk(from: stream)
    }

    private func getUnsignedChunk(from stream: Stream) async throws -> Data? {
        let chunk = try await stream.readAsync(upToCount: CHUNK_SIZE_BYTES) ?? Data()

        self.chunkBody = chunk

        // Early exit for empty chunk when already signed
        if chunk.isEmpty {
            return nil
        }

        return constructChunk(chunk: chunk, signature: nil)
    }

    func getSignedChunk(from stream: Stream) async throws -> Data? {
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
        let chunkSignature = try await Signer.signChunk(
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
        let trailerSignature = try await Signer.signTrailerHeaders(
            headers: trailingHeaders.toHttpHeaders(),
            previousSignature: previousSignature,
            config: crtTrailerSignerConfig
        )
        self.previousSignature = trailerSignature

        return trailerSignature
    }

    private func getTrailingHeadersString(trailingHeaders: Headers) -> String {
        return trailingHeaders.headers.flatMap { header in
            header.value.map { "\(header.name): \($0)\r\n"}
        }.joined()
    }
}

extension AwsChunkedReader {

    public func updateTrailingHeader(name: String, value: String) {
        self.trailingHeaders.update(name: name, value: value)
    }

    public func getTrailingHeaders() -> Headers {
        return self.trailingHeaders
    }

    public func getChecksumAlgorithm() -> HashFunction? {
        return self.checksum
    }

    public func setChecksumAlgorithm(checksum: HashFunction?) {
        self.checksum = checksum
    }

    func getCurrentChunk() -> Data {
        return self.chunk
    }

    func setCurrentChunk(chunk: Data) {
        self.chunk = chunk
    }

    func getCurrentChunkBody() -> Data {
        return self.chunkBody
    }

    func setCurrentChunkBody(chunk: Data) {
        self.chunkBody = chunk
    }
}

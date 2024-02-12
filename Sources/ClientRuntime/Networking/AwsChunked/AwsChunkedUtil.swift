//
//  File.swift
//  
//
//  Created by Yaffe, David on 1/23/24.
//

import AwsCommonRuntimeKit

extension SigningConfig {
    public var useAwsChunkedEncoding: Bool {
        switch self.signedBodyValue {
        case .streamingSha256Payload, .streamingSha256PayloadTrailer, .streamingUnSignedPayloadTrailer:
            return true
        default:
            return false
        }
    }
}

extension SdkHttpRequestBuilder {
    public func setAwsChunkedHeaders(checksumAlgorithm: HashFunction? = nil) throws {

        let body = self.getBody()

        // Check if self.body is of the case ByteStream.stream(let stream)
        if case .stream(let stream) = body {
            // Set the common headers for AWS-chunked encoding
            self.withHeader(name: "Content-Encoding", value: "aws-chunked")
            self.withHeader(name: "Transfer-Encoding", value: "chunked")
            if let checksum = checksumAlgorithm {
                self.withHeader(name: "x-amz-trailer", value: "x-amz-checksum-\(checksum)")
            }
            guard let decodedContentLength = stream.length else {
                throw ClientError.dataNotFound("Cannot use aws-chunked encoding with an unknown stream length!")
            }
            self.withHeader(name: "X-Amz-Decoded-Content-Length", value: String(decodedContentLength))
        } else {
            throw ClientError.dataNotFound("aws-chunked encoding requires a streaming payload!")
        }
    }

    public func setAwsChunkedBody(
        signingConfig: SigningConfig,
        signature: String,
        trailingHeaders: Headers,
        checksumAlgorithm: HashFunction? = nil
    ) throws {
        let body = self.getBody()
        switch body {
        case .stream(let stream):
            if let bufferedStream = stream as? BufferedStream {
                self.withBody(ByteStream.stream(AwsChunkedBufferedStream(
                    stream: bufferedStream,
                    signingConfig: signingConfig,
                    previousSignature: signature,
                    trailingHeaders: trailingHeaders,
                    checksumAlgorithm: checksumAlgorithm
                )))
            } else if let fileStream = stream as? FileStream {
                self.withBody(ByteStream.stream(AwsChunkedFileStream(
                    stream: fileStream,
                    signingConfig: signingConfig,
                    previousSignature: signature,
                    trailingHeaders: trailingHeaders,
                    checksumAlgorithm: checksumAlgorithm
                )))
            }
        default:
            throw ClientError.dataNotFound("Cannot set a non-stream body as an aws-chunked body!")
        }
    }
}

extension SigningConfig {

    func toChunkSigningConfig() -> SigningConfig {
        let modifiedSignatureType = SignatureType.requestChunk
        let modifiedBodyType = SignedBodyValue.empty
        return SigningConfig(
            algorithm: self.algorithm,
            signatureType: modifiedSignatureType,
            service: self.service,
            region: self.region,
            date: self.date,
            credentials: self.credentials,
            credentialsProvider: self.credentialsProvider,
            expiration: self.expiration,
            signedBodyHeader: self.signedBodyHeader,
            signedBodyValue: modifiedBodyType,
            shouldSignHeader: self.shouldSignHeader,
            useDoubleURIEncode: self.useDoubleURIEncode,
            shouldNormalizeURIPath: self.shouldNormalizeURIPath,
            omitSessionToken: self.omitSessionToken
        )
    }

    func toTrailingHeadersSigningConfig() -> SigningConfig {
        let modifiedSignatureType = SignatureType.requestTrailingHeaders
        let modifiedBodyType = SignedBodyValue.empty
        return SigningConfig(
            algorithm: self.algorithm,
            signatureType: modifiedSignatureType,
            service: self.service,
            region: self.region,
            date: self.date,
            credentials: self.credentials,
            credentialsProvider: self.credentialsProvider,
            expiration: self.expiration,
            signedBodyHeader: self.signedBodyHeader,
            signedBodyValue: modifiedBodyType,
            shouldSignHeader: self.shouldSignHeader,
            useDoubleURIEncode: self.useDoubleURIEncode,
            shouldNormalizeURIPath: self.shouldNormalizeURIPath,
            omitSessionToken: self.omitSessionToken
        )
    }

    var isUnsigned: Bool {
        return signedBodyValue == .streamingUnSignedPayloadTrailer
    }
}

extension Int {
    var hexString: String {
        return String(self, radix: 16)
    }
}

public func sendAwsChunkedBody(
    request: SdkHttpRequest,
    writeChunk: @escaping (Data, Bool) async throws -> Void
) async throws {
    let body = request.body

    guard case .stream(let stream) = body, stream.isEligibleForAwsChunkedStreaming() else {
        throw ByteStreamError.invalidStreamTypeForChunkedBody(
            "The stream is not eligible for AWS chunked streaming or is not a stream type!"
        )
    }

    guard let awsChunkedStream = stream as? AwsChunkedStream else {
        throw ByteStreamError.streamDoesNotConformToAwsChunkedStream(
            "Stream does not conform to AwsChunkedStream! Type is \(stream)."
        )
    }

    let chunkedReader = awsChunkedStream.getChunkedReader()

    var hasMoreChunks = true
    while hasMoreChunks {
        // Process the first chunk and determine if there are more to send
        hasMoreChunks = try await chunkedReader.processNextChunk()

        if !hasMoreChunks {
            // Send the final chunk
            let finalChunk = try await chunkedReader.getFinalChunk()
            try await writeChunk(finalChunk, true)
        } else {
            let currentChunkBody = chunkedReader.getCurrentChunkBody()
            if !currentChunkBody.isEmpty {
                try await writeChunk(chunkedReader.getCurrentChunk(), false)
            }
        }
    }
}

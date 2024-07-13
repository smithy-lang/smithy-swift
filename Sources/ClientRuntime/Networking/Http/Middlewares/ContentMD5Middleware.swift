// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import class Smithy.Context
import enum SmithyChecksumsAPI.ChecksumAlgorithm
import AwsCommonRuntimeKit
import SmithyChecksums
import SmithyHTTPAPI

public struct ContentMD5Middleware<OperationStackInput, OperationStackOutput> {
    public let id: String = "ContentMD5"

    private let contentMD5HeaderName = "Content-MD5"

    public init() {}

    private func addHeaders(builder: SdkHttpRequestBuilder, attributes: Context) async throws {
        // Skip MD5 hash if using checksums
        if builder.headers.exists(name: "x-amz-sdk-checksum-algorithm") {
            return
        }

        switch builder.body {
        case .data(let data):
            guard let data else {
                return
            }
            let md5Hash = try data.computeMD5()
            let base64Encoded = md5Hash.base64EncodedString()
            builder.updateHeader(name: "Content-MD5", value: base64Encoded)
        case .stream(let stream):
            let checksumAlgorithm: ChecksumAlgorithm = .md5
            let md5Hasher = checksumAlgorithm.createChecksum()
            do {
                // read chunks and update hasher
                while let chunk = try await stream.readAsync(upToCount: CHUNK_SIZE_BYTES), !chunk.isEmpty {
                    // Update the hasher with the chunk.
                    try md5Hasher.update(chunk: chunk)
                }

                // Finalize the hash after reading all chunks.
                let hashResult = try md5Hasher.digest().toBase64String()
                builder.updateHeader(name: "Content-MD5", value: hashResult)
            } catch {
                guard let logger = attributes.getLogger() else {
                    return
                }
                logger.error("Could not compute Content-MD5 of stream due to error \(error)")
            }
        default:
            guard let logger = attributes.getLogger() else {
                return
            }
            logger.error("Unhandled case for Content-MD5")
        }
    }
}

extension ContentMD5Middleware: HttpInterceptor {
    public typealias InputType = OperationStackInput
    public typealias OutputType = OperationStackOutput

    public func modifyBeforeTransmit(
        context: some MutableRequest<InputType, RequestType>
    ) async throws {
        let builder = context.getRequest().toBuilder()
        try await addHeaders(builder: builder, attributes: context.getAttributes())
        context.updateRequest(updated: builder.build())
    }
}

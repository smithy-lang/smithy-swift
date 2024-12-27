// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import Smithy
import enum SmithyChecksumsAPI.ChecksumAlgorithm
import AwsCommonRuntimeKit
import SmithyChecksums
import SmithyHTTPAPI

public struct ContentMD5Middleware<OperationStackInput, OperationStackOutput> {
    public let id: String = "ContentMD5"

    private let contentMD5HeaderName = "Content-MD5"

    public init() {}

    private func addHeaders(builder: HTTPRequestBuilder, attributes: Context) async throws {
        // Initialize logger
        guard let logger = attributes.getLogger() else {
            throw ClientError.unknownError("No logger found!")
        }

        // Skip MD5 hash if using flexible checksum
        if builder.headers.headers.contains(where: {
            $0.name.lowercased().starts(with: "x-amz-checksum-")
        }) {
            logger.debug("Flexible checksum configured. Skipping MD5 checksum calculation.")
            return
        }

        // Skip MD5 hash if it was provided in input by the user
        if builder.headers.headers.contains(where: {
            $0.name.lowercased() == "content-md5"
        }) {
            logger.debug("MD5 checksum hash provided in the input. Skipping MD5 checksum calculation.")
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
                logger.error("Could not compute Content-MD5 of stream due to error \(error)")
            }
        default:
            logger.error("Unhandled case for Content-MD5")
        }
    }
}

extension ContentMD5Middleware: Interceptor {
    public typealias InputType = OperationStackInput
    public typealias OutputType = OperationStackOutput
    public typealias RequestType = SmithyHTTPAPI.HTTPRequest
    public typealias ResponseType = HTTPResponse

    public func modifyBeforeSigning(
        context: some MutableRequest<InputType, RequestType>
    ) async throws {
        let builder = context.getRequest().toBuilder()
        try await addHeaders(builder: builder, attributes: context.getAttributes())
        context.updateRequest(updated: builder.build())
    }
}

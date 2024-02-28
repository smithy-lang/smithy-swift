// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

import AwsCommonRuntimeKit

public struct ContentMD5Middleware<OperationStackOutput>: Middleware {
    public let id: String = "ContentMD5"

    private let contentMD5HeaderName = "Content-MD5"

    public init() {}

    public func handle<H>(context: Context,
                          input: MInput,
                          next: H) async throws -> MOutput
    where H: Handler,
    Self.MInput == H.Input,
    Self.MOutput == H.Output,
    Self.Context == H.Context {

        // Skip MD5 hash if using checksums
        if input.headers.exists(name: "x-amz-sdk-checksum-algorithm") {
            return try await next.handle(context: context, input: input)
        }

        switch input.body {
        case .data(let data):
            guard let data else {
                return try await next.handle(context: context, input: input)
            }
            let md5Hash = try data.computeMD5()
            let base64Encoded = md5Hash.base64EncodedString()
            input.headers.update(name: "Content-MD5", value: base64Encoded)
        case .stream(let stream):
            let checksum: HashFunction = .md5
            do {
                if let md5Hasher = checksum.createHash() {
                    // read chunks and update hasher
                    while let chunk = try await stream.readAsync(upToCount: CHUNK_SIZE_BYTES), !chunk.isEmpty {
                        // Update the hasher with the chunk.
                        try md5Hasher.update(data: chunk)
                    }

                    // Finalize the hash after reading all chunks.
                    let hashResult = try HashResult.data(md5Hasher.finalize())
                    input.headers.update(name: "Content-MD5", value: hashResult.toBase64String())
                }
            } catch {
                guard let logger = context.getLogger() else {
                    return try await next.handle(context: context, input: input)
                }
                logger.error("Could not compute Content-MD5 of stream due to error \(error)")
            }
        default:
            guard let logger = context.getLogger() else {
                return try await next.handle(context: context, input: input)
            }
            logger.error("Unhandled case for Content-MD5")
        }

        return try await next.handle(context: context, input: input)
    }

    public typealias MInput = SdkHttpRequestBuilder
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext
}

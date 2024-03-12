// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

public struct FlexibleChecksumsResponseMiddleware<OperationStackOutput>: Middleware {

    public let id: String = "FlexibleChecksumsResponseMiddleware"

    // The priority to validate response checksums, if multiple are present
    let CHECKSUM_HEADER_VALIDATION_PRIORITY_LIST: [String] = [
        ChecksumAlgorithm.crc32c,
        .crc32,
        .sha1,
        .sha256
    ].sorted().map { $0.toString() }

    let validationMode: Bool
    let priorityList: [String]

    public init(validationMode: Bool, priorityList: [String] = []) {
        self.validationMode = validationMode
        self.priorityList = !priorityList.isEmpty
            ? withPriority(checksums: priorityList)
            : CHECKSUM_HEADER_VALIDATION_PRIORITY_LIST
    }

    public func handle<H>(context: Context,
                          input: SdkHttpRequest,
                          next: H) async throws -> OperationOutput<OperationStackOutput>
    where H: Handler,
    Self.MInput == H.Input,
    Self.MOutput == H.Output,
    Self.Context == H.Context {

        // The name of the checksum header which was validated. If `null`, validation was not performed.
        context.attributes.set(key: AttributeKey<String>(name: "ChecksumHeaderValidated"), value: nil)

        // Initialize logger
        guard let logger = context.getLogger() else {
            throw ClientError.unknownError("No logger found!")
        }

        // Exit if validation should not be performed
        if !validationMode {
            logger.info("Checksum validation should not be performed! Skipping workflow...")
            return try await next.handle(context: context, input: input)
        }

        // Get the response
        let output = try await next.handle(context: context, input: input)
        let httpResponse = output.httpResponse

        // Determine if any checksum headers are present
        let checksumHeaderIsPresent = priorityList.first {
            httpResponse.headers.value(for: "x-amz-checksum-\($0)") != nil
        }

        guard let checksumHeader = checksumHeaderIsPresent else {
            let message =
                "User requested checksum validation, but the response headers did not contain any valid checksums"
            logger.warn(message)
            return output
        }

        let fullChecksumHeader = "x-amz-checksum-" + checksumHeader

        // let the user know which checksum will be validated
        logger.debug("Validating checksum from \(fullChecksumHeader)")
        context.attributes.set(key: AttributeKey<String>(name: "ChecksumHeaderValidated"), value: fullChecksumHeader)

        let checksumString = checksumHeader.removePrefix("x-amz-checksum-")
        guard let responseChecksum = ChecksumAlgorithm.from(string: checksumString) else {
            throw ClientError.dataNotFound("Checksum found in header is not supported!")
        }
        guard let expectedChecksum = httpResponse.headers.value(for: fullChecksumHeader) else {
            throw ClientError.dataNotFound("Could not determine the expected checksum!")
        }

        func handleNormalPayload(_ data: Data?) throws {

            guard let data else {
                throw ClientError.dataNotFound("Cannot calculate checksum of empty body!")
            }

            let calculatedChecksum = try responseChecksum.computeHash(of: data)

            let actualChecksum = calculatedChecksum.toBase64String()

            guard expectedChecksum == actualChecksum else {
                let message = "Checksum mismatch. Expected \(expectedChecksum) but was \(actualChecksum)"
                throw ChecksumMismatchException.message(message)
            }
        }

        func handleStreamPayload(_ stream: Stream) throws {
            let validatingStream = ByteStream.getChecksumValidatingBody(
                stream: stream,
                expectedChecksum: expectedChecksum,
                checksumAlgorithm: responseChecksum
            )

            // Set the response to a validating stream
            context.response = output.httpResponse
            context.response?.body = validatingStream
        }

        // Handle body vs handle stream
        switch httpResponse.body {
        case .data(let data):
            try handleNormalPayload(data)
        case .stream(let stream):
            try handleStreamPayload(stream)
        case .noStream:
            throw ClientError.dataNotFound("Cannot calculate the checksum of an empty body!")
        }

        return output
    }

    public typealias MInput = SdkHttpRequest
    public typealias MOutput = OperationOutput<OperationStackOutput>
    public typealias Context = HttpContext
}

enum ChecksumMismatchException: Error {
    case message(String)
}

private func withPriority(checksums: [String]) -> [String] {
    let checksumsMap = checksums.compactMap { ChecksumAlgorithm.from(string: $0) }
    return checksumsMap.sorted().map { $0.toString() }
}

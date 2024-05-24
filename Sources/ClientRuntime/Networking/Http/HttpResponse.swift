//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol SmithyStreamsAPI.Stream
import protocol SmithyReadWrite.WireDataProviding
import AwsCommonRuntimeKit

public class HttpResponse: HttpUrlResponse, ResponseMessage {

    public var headers: Headers
    public var body: ByteStream
    public var statusCode: HttpStatusCode

    public init(headers: Headers = .init(), statusCode: HttpStatusCode = .processing, body: ByteStream = .noStream) {
        self.headers = headers
        self.statusCode = statusCode
        self.body = body
    }

    public init(headers: Headers = .init(), body: ByteStream, statusCode: HttpStatusCode) {
        self.body = body
        self.statusCode = statusCode
        self.headers = headers
    }
}

extension HttpResponse: CustomDebugStringConvertible {
    public var debugDescriptionWithBody: String {
        return debugDescription + "\nResponseBody: \(body.debugDescription)"
    }
    public var debugDescription: String {
        return "\nStatus Code: \(statusCode.description) \n \(headers)"
    }
}

extension HttpResponse: WireDataProviding {

    public func data() async throws -> Data {
        let data = try await body.readData()
        body = .data(data)
        return data ?? Data()
    }
}

extension ByteStream {

    // Convert the body stream to a ValidatingFileStream to check checksums
    public static func getChecksumValidatingBody(
        stream: Stream,
        expectedChecksum: String,
        checksumAlgorithm: ChecksumAlgorithm
    ) -> ByteStream {
        if let bufferedStream = stream as? BufferedStream {
            return ByteStream.stream(
                ValidatingBufferedStream(
                    stream: bufferedStream,
                    expectedChecksum: expectedChecksum,
                    checksumAlgorithm: checksumAlgorithm
                )
            )
        }
        return ByteStream.stream(stream)
    }
}

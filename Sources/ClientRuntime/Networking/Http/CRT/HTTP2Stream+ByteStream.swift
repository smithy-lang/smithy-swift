//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.ByteStream
import struct Smithy.Attributes
import AwsCommonRuntimeKit

extension HTTP2Stream {
    /// Returns the recommended size, in bytes, for the data to write
    /// when using manual writes to HTTP2Stream
    var manualWriteBufferSize: Int {
        return 1024
    }

    /// Writes the ByteStream to the stream asynchronously
    /// There is no recommended size for the data to write. The data will be written in chunks of `manualWriteBufferSize` bytes.
    /// - Parameter body: The body to write
    /// - Throws: Throws an error if the write fails
    func write(body: ByteStream, telemetry: HttpTelemetry, serverAddress: String) async throws {
        let context = telemetry.contextManager.current()
        var bytesSentAttributes = Attributes()
        bytesSentAttributes.set(key: HttpMetricsAttributesKeys.serverAddress, value: serverAddress)
        switch body {
        case .data(let data):
            try await writeChunk(chunk: data ?? .init(), endOfStream: true)
            telemetry.bytesSent.add(
                value: data?.count ?? 0,
                attributes: bytesSentAttributes,
                context: context)
        case .stream(let stream):
            while let data = try await stream.readAsync(upToCount: manualWriteBufferSize) {
                try await writeChunk(chunk: data, endOfStream: false)
                telemetry.bytesSent.add(
                    value: data.count,
                    attributes: bytesSentAttributes,
                    context: context)
            }
            try await writeChunk(chunk: .init(), endOfStream: true)
        case .noStream:
            try await writeChunk(chunk: .init(), endOfStream: true)
        }
    }
}

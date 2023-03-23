//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCommonRuntimeKit

extension HTTP2Stream {
    /// Returns the recommended size, in bytes, for the data to write
    /// when using manual writes to HTTP2Stream
    var manualWriteBufferSize: Int {
        return 1024
    }

    /// Writes the HttpBody to the stream asynchronously
    /// There is not recommended size for the data to write. The data will be written in chunks of `manualWriteBufferSize` bytes.
    /// - Parameter body: The body to write
    /// - Throws: Throws an error if the write fails
    func write(body: HttpBody) async throws {
        switch body {
        case .data(let data):
            try await writeData(data: data ?? .init(), endOfStream: true)
        case .stream(let stream):
            while let data = try await stream.readAsync(upToCount: manualWriteBufferSize) {
                try await writeData(data: data, endOfStream: false)
            }
            try await writeData(data: .init(), endOfStream: true)
        case .none:
            try await writeData(data: .init(), endOfStream: true)
        }
    }
}

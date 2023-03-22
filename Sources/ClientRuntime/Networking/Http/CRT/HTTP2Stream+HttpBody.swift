//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AwsCommonRuntimeKit

extension HTTP2Stream {
    /// Writes the HttpBody to the stream asynchronously
    /// There is not recommended size for the data to write. The data will be written in chunks of 1024 bytes.
    /// - Parameter body: The body to write
    /// - Throws: Throws an error if the write fails
    func write(body: HttpBody) async throws {
        switch body {
        case .data(let data):
            try await writeData(data: data ?? .init(), endOfStream: true)
        case .stream(let stream):
            while let data = try await stream.readAsync(upToCount: 1024) {
                try await writeData(data: data, endOfStream: false)
            }
            try await writeData(data: .init(), endOfStream: true)
        case .none:
            try await writeData(data: .init(), endOfStream: true)
        }
    }
}

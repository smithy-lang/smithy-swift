//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import class Foundation.JSONSerialization
import class Foundation.NSError
import class Foundation.NSNull
import struct SmithySerialization.InvalidEncodingError

extension Reader {

    public static func from(data: Data) throws -> Reader {
        // Empty bodies are allowed.  When the body is empty,
        // return a reader with no JSON content.
        guard !data.isEmpty else { return Reader(nodeInfo: "", parent: nil) }

        // Attempt to parse JSON from the non-empty body.
        // Throw an error if JSON is invalid.
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            return try Reader(nodeInfo: "", jsonObject: jsonObject)
        } catch {
            throw InvalidEncodingError(wrapped: error)
        }
    }
}

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
import struct SmithySerde.InvalidEncodingError

extension Reader {

    public static func from(data: Data) throws -> Reader {
        // Empty bodies are allowed.  When the body is empty,
        // return a reader with no JSON content.
        guard !data.isEmpty else { return try Reader(nodeInfo: "", jsonObject: [:]) }

        // Attempt to parse JSON from the non-empty body.
        // Throw an error if JSON is invalid.
        // (Determine whether to wrap this error)
        let jsonObject: Any
        do {
            jsonObject = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw InvalidEncodingError(wrapped: error)
        }
        return try Reader(nodeInfo: "", jsonObject: jsonObject)
    }
}

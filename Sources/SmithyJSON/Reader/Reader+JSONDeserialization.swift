//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import class Foundation.JSONSerialization
import class Foundation.NSNull

extension Reader {

    public static func from(data: Data) throws -> Reader {
        guard !data.isEmpty else { return Reader(nodeInfo: "", parent: nil) }
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        return try Reader(nodeInfo: "", jsonObject: jsonObject)
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import class Foundation.JSONSerialization

extension Reader {

    public static func from(data: Data) throws -> Reader {
        let jsonObject = try JSONSerialization.jsonObject(with: data)
        let rootNode = try JSONNode(jsonObject: jsonObject)
        return Reader(nodeInfo: "")
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import class Foundation.NSError
import class Foundation.JSONSerialization
import class Foundation.NSNull

extension Reader {

    public static func from(data: Data) throws -> Reader {
        guard !data.isEmpty else { return Reader(nodeInfo: "", parent: nil) }
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
            return try Reader(nodeInfo: "", jsonObject: jsonObject)
        } catch let error as NSError where error.domain == "NSCocoaErrorDomain" && error.code == 3840 {
            return try Reader(nodeInfo: "", jsonObject: [:])
        }
    }
}

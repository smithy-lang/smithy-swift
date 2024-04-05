//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import class Foundation.JSONSerialization

extension Writer {

    public func data() throws -> Data {
        try JSONSerialization.data(withJSONObject: json.jsonObject, options: [])
    }
}

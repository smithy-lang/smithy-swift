//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import struct Foundation.URL

public struct SmithyModel {
    public let count: Int

    public init(modelFileURL: URL) throws {
        let modelData = try Data(contentsOf: modelFileURL)
        self.count = modelData.count
    }
}

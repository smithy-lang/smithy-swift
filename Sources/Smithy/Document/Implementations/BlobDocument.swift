//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data

@_spi(SmithyDocumentImpl)
public struct BlobDocument: Document {
    public var type: ShapeType { .blob }
    let value: Data

    public init(value: Data) {
        self.value = value
    }

    public func asBlob() throws -> Data {
        value
    }
}

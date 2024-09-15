//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SmithyDocumentImpl)
public struct StringDocument: Document {
    public var type: ShapeType { .string }
    let value: String

    public init(value: String) {
        self.value = value
    }

    public func asString() throws -> String {
        value
    }
}

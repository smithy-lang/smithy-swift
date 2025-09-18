//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import protocol Smithy.SmithyDocument
@_spi(SmithyDocumentImpl) import struct Smithy.StringMapDocument
@_spi(SmithyDocumentImpl) import struct Smithy.ListDocument
@_spi(SmithyDocumentImpl) import struct Smithy.StringDocument
@_spi(SmithyDocumentImpl) import struct Smithy.DoubleDocument
@_spi(SmithyDocumentImpl) import struct Smithy.BooleanDocument

extension TraitNode {

    public func toDocument() -> (any SmithyDocument)? {
        switch self {
        case .object(let value):
            return StringMapDocument(value: value.compactMapValues { $0.toDocument() })
        case .list(let value):
            return ListDocument(value: value.compactMap { $0.toDocument() })
        case .string(let value):
            return StringDocument(value: value)
        case .number(let value):
            return DoubleDocument(value: value)
        case .boolean(let value):
            return BooleanDocument(value: value)
        case .null:
            return nil
        }
    }
}

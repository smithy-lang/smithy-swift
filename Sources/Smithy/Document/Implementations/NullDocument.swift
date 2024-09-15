//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SmithyDocumentImpl)
public struct NullDocument: Document {
    public var type: ShapeType { .structure }  // think of this as a Unit structure

    public init() {}
}

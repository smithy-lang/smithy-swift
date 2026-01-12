//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.ShapeID

public struct TypeRegistry {
    private let typeMap: [ShapeID: DeserializableShape.Type]
    private let noNamespaceTypeMap: [ShapeID: DeserializableShape.Type]

    public init(_ typeMap: [ShapeID: DeserializableShape.Type]) {
        self.typeMap = typeMap
        let noNamespacePairs = typeMap.map { (key, value) in (ShapeID("", key.name, nil), value) }
        self.noNamespaceTypeMap = Dictionary(uniqueKeysWithValues: noNamespacePairs)
    }

    public subscript(shapeID: ShapeID) -> DeserializableShape.Type? {
        typeMap[shapeID] ?? noNamespaceTypeMap[.init("", shapeID.name, nil)]
    }
}

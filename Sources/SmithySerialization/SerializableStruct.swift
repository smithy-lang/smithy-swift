//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol SerializableStruct: SerializableShape {
    func serializeMembers(_ serializer: any ShapeSerializer)
}

public extension SerializableStruct {

    func serialize(_ serializer: any ShapeSerializer) {
        serializer.writeStruct(schema: Self.schema, value: self)
    }
}

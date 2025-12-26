//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol SerializableStruct: SerializableShape {
    static var writeConsumer: WriteStructConsumer<Self> { get }
}

public extension SerializableStruct {

    func serialize(_ serializer: any ShapeSerializer) throws {
        try serializer.writeStruct(Self.schema, self)
    }
}

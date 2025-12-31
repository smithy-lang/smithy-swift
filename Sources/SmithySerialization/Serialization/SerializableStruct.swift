//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public protocol SerializableStruct: SerializableShape, CustomDebugStringConvertible {
    static var writeConsumer: WriteStructConsumer<Self> { get }
}

public extension SerializableStruct {

    func serialize(_ serializer: any ShapeSerializer) throws {
        try serializer.writeStruct(Self.schema, self)
    }

    var debugDescription: String {
        let serializer = StringSerializer()
        try! serialize(serializer)
        return serializer.string
    }
}

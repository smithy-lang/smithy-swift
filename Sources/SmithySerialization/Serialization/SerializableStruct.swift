//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
import class Smithy.Schema

@_spi(SchemaBasedSerde)
public typealias WriteStructConsumer<T> = (Schema, T, any ShapeSerializer) throws -> Void

@_spi(SchemaBasedSerde)
public protocol SerializableStruct: SerializableShape, CustomStringConvertible, CustomDebugStringConvertible {
    static var writeConsumer: WriteStructConsumer<Self> { get }
}

@_spi(SchemaBasedSerde)
public extension SerializableStruct {

    /// A written description of this type and its contents.
    ///
    /// Fields marked with the `sensitive` trait will be written to the description as "redacted".
    var description: String {
        let serializer = StringSerializer()
        do {
            try serialize(serializer)
            return serializer.string
        } catch {
            return "[Logging error in SerializableStruct.description, " +
                "please file a bug at https://github.com/smithy-lang/smithy-swift]"
        }
    }

    /// A written description of this type and its contents.
    ///
    /// Fields marked with the `sensitive` trait will be written to the description as "redacted".
    var debugDescription: String { description }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
import enum Smithy.Prelude
@_spi(SchemaBasedSerde)
import class Smithy.Schema
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.DeserializableStruct
@_spi(SchemaBasedSerde)
import typealias SmithySerialization.ReadStructConsumer
@_spi(SchemaBasedSerde)
import protocol SmithySerialization.ShapeDeserializer

struct BaseError {
    var __type: String?
    var code: String?
    var message: String?
}

extension BaseError: DeserializableStruct {

    private static var schema: Schema {
        .init(
            id: .init("swift.synthetic", "BaseError"),
            type: .structure,
            members: [
                .init(
                    id: .init("swift.synthetic", "BaseError", "__type"),
                    type: .member,
                    target: Prelude.stringSchema,
                    index: 0
                ),
                .init(
                    id: .init("swift.synthetic", "BaseError", "code"),
                    type: .member,
                    target: Prelude.stringSchema,
                    index: 1
                ),
                .init(
                    id: .init("swift.synthetic", "BaseError", "message"),
                    type: .member,
                    target: Prelude.stringSchema,
                    index: 2
                ),
            ]
        )
    }

    public static var readConsumer: SmithySerialization.ReadStructConsumer<Self> {
        { memberSchema, value, deserializer in
            switch memberSchema.index {
            case 0:
                value.__type = try deserializer.readString(memberSchema)
            case 1:
                value.code = try deserializer.readString(memberSchema)
            case 2:
                value.message = try deserializer.readString(memberSchema)
            default:
                break
            }
        }
    }

    public static func deserialize(_ deserializer: any ShapeDeserializer) throws -> Self {
        var value = Self()
        try deserializer.readStruct(Self.schema, &value)
        return value
    }
}

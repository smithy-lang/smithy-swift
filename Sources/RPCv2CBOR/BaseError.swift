//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Smithy.Schema
import enum Smithy.Prelude
import protocol SmithySerialization.DeserializableStruct
import typealias SmithySerialization.ReadStructConsumer
import protocol SmithySerialization.ShapeDeserializer

struct RPCv2CBORBaseError: DeserializableStruct {

    static var schema: Smithy.Schema {
        .init(
            id: .init("swift.synthetic", "RPCv2CBORBaseError"),
            type: .structure,
            members: [
                .init(
                    id: .init("swift.synthetic", "RPCv2CBORBaseError", "__type"),
                    type: .member,
                    target: Prelude.stringSchema,
                    index: 0
                ),
                .init(
                    id: .init("swift.synthetic", "RPCv2CBORBaseError", "message"),
                    type: .member,
                    target: Prelude.stringSchema,
                    index: 1
                )
            ]
        )
    }

    static var readConsumer: SmithySerialization.ReadStructConsumer<Self> {
        { memberSchema, value, deserializer in
            switch memberSchema.index {
            case 0:
                value.__type = try deserializer.readString(memberSchema)
            case 1:
                value.message = try deserializer.readString(memberSchema)
            default:
                break
            }
        }
    }

    static func deserialize(_ deserializer: any ShapeDeserializer) throws -> Self {
        var value = Self()
        try deserializer.readStruct(Self.schema, &value)
        return value
    }

    var __type: String?
    var message: String?
}

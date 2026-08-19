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
import protocol SmithySerialization.ShapeDeserializer

struct BaseError {
    var __type: String?
    var code: String?

    /// The message, from the `message` JSON key.
    var message: String?

    /// The message, from the `Message` JSON key.  Used by some services.
    var capitalizedMessage: String?

    /// The message, from the `errorMessage` JSON key.  Used by some services.
    var errorMessage: String?

    /// The error message conveyed in the response body, from whichever message key is present.
    var resolvedMessage: String? {
        self.message ?? self.capitalizedMessage ?? self.errorMessage
    }
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
                .init(
                    id: .init("swift.synthetic", "BaseError", "Message"),
                    type: .member,
                    target: Prelude.stringSchema,
                    index: 3
                ),
                .init(
                    id: .init("swift.synthetic", "BaseError", "errorMessage"),
                    type: .member,
                    target: Prelude.stringSchema,
                    index: 4
                ),
            ]
        )
    }

    public mutating func deserializeMember(_ memberSchema: Schema, _ deserializer: any ShapeDeserializer) throws {
        switch memberSchema.index {
        case 0:
            self.__type = try deserializer.readString(memberSchema)
        case 1:
            self.code = try deserializer.readString(memberSchema)
        case 2:
            self.message = try deserializer.readString(memberSchema)
        case 3:
            self.capitalizedMessage = try deserializer.readString(memberSchema)
        case 4:
            self.errorMessage = try deserializer.readString(memberSchema)
        default:
            break
        }
    }

    public static func deserialize(_ deserializer: any ShapeDeserializer) throws -> Self {
        var value = Self()
        try deserializer.readStruct(Self.schema, &value)
        return value
    }
}

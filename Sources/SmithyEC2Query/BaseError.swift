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

/// The fields common to every ec2Query error, from the `Errors/Error` element of the error response.
///
/// See https://smithy.io/2.0/aws/protocols/aws-ec2-query-protocol.html#operation-error-serialization
struct BaseError {
    var code: String?
    var message: String?
}

extension BaseError: DeserializableStruct {

    private static let schema = Schema(
        id: .init("swift.synthetic", "BaseError"),
        type: .structure,
        members: [
            .init(
                id: .init("swift.synthetic", "BaseError", "Code"),
                type: .member,
                target: Prelude.stringSchema,
                index: 0
            ),
            .init(
                id: .init("swift.synthetic", "BaseError", "Message"),
                type: .member,
                target: Prelude.stringSchema,
                index: 1
            ),
        ]
    )

    mutating func deserializeMember(_ memberSchema: Schema, _ deserializer: any ShapeDeserializer) throws {
        switch memberSchema.index {
        case 0:
            self.code = try deserializer.readString(memberSchema)
        case 1:
            self.message = try deserializer.readString(memberSchema)
        default:
            break
        }
    }

    static func deserialize(_ deserializer: any ShapeDeserializer) throws -> Self {
        var value = Self()
        try deserializer.readStruct(Self.schema, &value)
        return value
    }
}

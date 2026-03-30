//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Prelude
import struct Smithy.Schema
import protocol SmithySerialization.DeserializableStruct
import typealias SmithySerialization.ReadStructConsumer
import protocol SmithySerialization.ShapeDeserializer

@_spi(RestXML)
public struct BaseError {
    public var code: String?
    public var message: String?
    public var requestId: String?
}

extension BaseError: DeserializableStruct {

    /// Schema for the `<Error>` wrapper element in RestXML error responses.
    private static var errorSchema: Smithy.Schema {
        .init(
            id: .init("swift.synthetic", "RestXMLBaseError"),
            type: .structure,
            members: [
                .init(
                    id: .init("swift.synthetic", "RestXMLBaseError", "Code"),
                    type: .member,
                    containerType: .structure,
                    target: Prelude.stringSchema,
                    index: 0
                ),
                .init(
                    id: .init("swift.synthetic", "RestXMLBaseError", "Message"),
                    type: .member,
                    containerType: .structure,
                    target: Prelude.stringSchema,
                    index: 1
                ),
                .init(
                    id: .init("swift.synthetic", "RestXMLBaseError", "RequestId"),
                    type: .member,
                    containerType: .structure,
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
                value.code = try deserializer.readString(memberSchema)
            case 1:
                value.message = try deserializer.readString(memberSchema)
            case 2:
                value.requestId = try deserializer.readString(memberSchema)
            default:
                break
            }
        }
    }

    public static func deserialize(_ deserializer: any ShapeDeserializer) throws -> Self {
        var value = Self()
        try deserializer.readStruct(Self.errorSchema, &value)
        return value
    }
}

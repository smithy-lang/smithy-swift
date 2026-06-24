//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
import struct Smithy.ShapeID

extension ShapeID {

    var preludeSchemaVarName: String {
        get throws {
            let propertyName = switch name {
                case "Unit": "unitSchema"
                case "String": "stringSchema"
                case "Blob": "blobSchema"
                case "Integer": "integerSchema"
                case "Timestamp": "timestampSchema"
                case "Boolean": "booleanSchema"
                case "Float": "floatSchema"
                case "Double": "doubleSchema"
                case "Long": "longSchema"
                case "Short": "shortSchema"
                case "Byte": "byteSchema"
                case "PrimitiveInteger": "primitiveIntegerSchema"
                case "PrimitiveBoolean": "primitiveBooleanSchema"
                case "PrimitiveFloat": "primitiveFloatSchema"
                case "PrimitiveDouble": "primitiveDoubleSchema"
                case "PrimitiveLong": "primitiveLongSchema"
                case "PrimitiveShort": "primitiveShortSchema"
                case "PrimitiveByte": "primitiveByteSchema"
                case "Document": "documentSchema"
                default: throw ModelError("Unhandled prelude type converted to schemaVar: \"\(name)\"")
                }
            return "Smithy.Prelude.\(propertyName)"
        }
    }

    var schemaVarName: String {
        get throws {
            let namespacePortion = namespace.replacingOccurrences(of: ".", with: "_")
            let namePortion = name
            if let member {
                return "member__\(namespacePortion)__\(namePortion)__\(member)"
            } else {
                return "schema__\(namespacePortion)__\(namePortion)"
            }
        }
    }
}

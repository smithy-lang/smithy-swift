//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.ShapeID

extension Shape {

    var schemaVarName: String {
        if id.namespace == "smithy.api" {
            id.preludeSchemaVarName
        } else {
            id.schemaVarName
        }
    }
}

private extension ShapeID {

    var preludeSchemaVarName: String {
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
            default: fatalError("Unhandled prelude type converted to schemaVar: \"\(name)\"")
            }
        return "Smithy.Prelude.\(propertyName)"
    }

    var schemaVarName: String {
        guard member == nil else { fatalError("Assigning member schema to a var") }
        let namespacePortion = namespace.replacingOccurrences(of: ".", with: "_")
        let namePortion = name
        return "schema__\(namespacePortion)__\(namePortion)"
    }
}

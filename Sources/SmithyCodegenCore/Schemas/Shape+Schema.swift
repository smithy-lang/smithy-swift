//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

extension Shape {
    func schemaVarName() throws -> String {
        if id.namespace == "smithy.api" {
            try id.preludeSchemaVarName()
        } else {
            try id.schemaVarName()
        }
    }
}

extension ShapeID {

    func preludeSchemaVarName() throws -> String {
        let propertyName =
            switch name {
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
            default: throw CodegenError("Unhandled prelude type converted to schemaVar: \"\(name)\"")
            }
        return "Smithy.Prelude.\(propertyName)"
    }

    func schemaVarName() throws -> String {
        guard member == nil else { throw CodegenError("Assigning member schema to a var") }
        let namespacePortion = namespace.replacingOccurrences(of: ".", with: "_")
        let namePortion = name
        return "schema2__\(namespacePortion)__\(namePortion)"
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Locale
import struct Foundation.NSRange
import class Foundation.NSRegularExpression
@_spi(SchemaBasedSerde)
import struct Smithy.ErrorTrait
@_spi(SchemaBasedSerde)
import struct Smithy.ServiceTrait
@_spi(SchemaBasedSerde)
import struct Smithy.ShapeID
@_spi(SchemaBasedSerde)
import struct Smithy.StreamingTrait

@_spi(SchemaBasedSerde)
public struct SymbolProvider {
    let service: ServiceShape
    let settings: SwiftSettings
    let model: Model

    init(service: ServiceShape, settings: SwiftSettings, model: Model) {
        self.service = service
        self.settings = settings
        self.model = model
    }

    public func swiftType(shape: Shape, forParamUse: Bool = false) throws -> String {
        switch shape.type {
        case .structure, .union, .enum, .intEnum:
            let baseName = (service.renames[shape.id] ?? shape.id.name).capitalized.escapingReservedWords
            if shape.isTopLevel {
                return baseName
            } else if shape.type == .intEnum {
                // The NestedShapeTransformer in main codegen inadvertently excludes intEnum
                // so it is not namespaced here.  All other shape types are in the namespace.
                return baseName
            } else {
                return try "\(modelNamespace).\(baseName)"
            }
        case .list, .set:
            guard let listShape = shape as? ListShape else {
                throw SymbolProviderError("Shape has type .list but is not a ListShape")
            }
            let elementType = try swiftType(shape: listShape.member.target)
            let opt = try NullableIndex().isNonOptional(listShape.member) ? "" : "?"
            return "[\(elementType)\(opt)]"
        case .map:
            guard let mapShape = shape as? MapShape else {
                throw SymbolProviderError("Shape has type .map but is not a MapShape")
            }
            let valueType = try swiftType(shape: mapShape.value.target)
            let opt = try NullableIndex().isNonOptional(mapShape.value) ? "" : "?"
            return "[Swift.String: \(valueType)\(opt)]"
        case .string:
            return "Swift.String"
        case .boolean:
            return "Swift.Bool"
        case .byte:
            return "Swift.Int8"
        case .short:
            return "Swift.Int16"
        case .integer, .long:
            return "Swift.Int"
        case .bigInteger:
            return "Swift.Int64"
        case .float:
            return "Swift.Float"
        case .double, .bigDecimal:
            return "Swift.Double"
        case .blob:
            if shape.hasTrait(StreamingTrait.self) {
                return "Smithy.ByteStream"
            } else {
                return "Foundation.Data"
            }
        case .timestamp:
            return "Foundation.Date"
        case .document:
            return forParamUse ? "(any Smithy.SmithyDocument)" : "Smithy.Document"
        case .service:
            return "\(settings.serviceName)Client"
        case .member, .operation, .resource:
            throw SymbolProviderError("Cannot provide Swift symbol for shape type \(shape.type)")
        }
    }

    public func operationMethodName(operation: OperationShape) throws -> String {
        return operation.id.name.toLowerCamelCase().escapingReservedWords
    }

    public func propertyName(shapeID: ShapeID) throws -> String {
        guard let member = shapeID.member else { throw SymbolProviderError("Shape ID has no member name") }
        return member.toLowerCamelCase().escapingReservedWords
    }

    public func enumCaseName(shapeID: ShapeID) throws -> String {
        try propertyName(shapeID: shapeID).lowercased().escapingReservedWords
    }

    public func schemaVarName(shape: Shape, namespaced: Bool = true) throws -> String {
        let namespace = try namespaced ? "\(schemaNamespace)." : ""
        return if shape.id.namespace == "smithy.api" {
            try "\(namespace)\(shape.id.preludeSchemaVarName)"
        } else {
            try "\(namespace)\(shape.id.schemaVarName)"
        }
    }

    var schemaNamespace: String {
        get throws {
            try swiftType(shape: service).appending("Schemas")
        }
    }

    private var modelNamespace: String {
        get throws {
            try swiftType(shape: service).appending("Types")
        }
    }
}

private extension Shape {

    var isTopLevel: Bool {
        hasTrait(UsedAsInputTrait.self) || hasTrait(UsedAsOutputTrait.self) || hasTrait(ErrorTrait.self)
    }
}

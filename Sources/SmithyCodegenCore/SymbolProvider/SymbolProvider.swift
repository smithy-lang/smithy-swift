//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Locale
import struct Foundation.NSRange
import class Foundation.NSRegularExpression
import struct Smithy.ErrorTrait
import struct Smithy.ServiceTrait
import struct Smithy.ShapeID

public struct SymbolProvider {
    let service: ServiceShape
    let settings: SwiftSettings
    let model: Model

    init(service: ServiceShape, settings: SwiftSettings, model: Model) {
        self.service = service
        self.settings = settings
        self.model = model
    }

    var serviceName: String {
        get throws {
            return try service.sdkIdStrippingService
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "Service", with: "")
        }
    }

    public func swiftType(shape: Shape) throws -> String {
        switch shape.type {
        case .structure, .union, .enum, .intEnum:
            let base = shape.id.name
            if shape.isTopLevel {
                return base.capitalized.escapingReservedWords
            } else if shape.type == .intEnum {
                // The NestedShapeTransformer in main codegen inadvertently excludes intEnum
                // so it is not namespaced here.  All other shape types are in the namespace.
                return base.capitalized.escapingReservedWords
            } else {
                return try "\(modelNamespace).\(base.capitalized.escapingReservedWords)"
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
            return "Smithy.Document"
        case .service:
            return "\(settings.sdkId.toUpperCamelCase())Client"
        case .member, .operation, .resource:
            throw SymbolProviderError("Cannot provide Swift symbol for shape type \(shape.type)")
        }
    }

    static let locale = Locale(identifier: "en_US_POSIX")

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

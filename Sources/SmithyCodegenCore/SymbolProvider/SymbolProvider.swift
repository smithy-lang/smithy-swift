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
import struct Smithy.InputTrait
import struct Smithy.OutputTrait
import struct Smithy.ServiceTrait
import struct Smithy.ShapeID

public struct SymbolProvider {
    let service: ServiceShape
    let model: Model

    init(service: ServiceShape, model: Model) {
        self.service = service
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
            if shape.hasTrait(InputTrait.self) || shape.hasTrait(OutputTrait.self) || shape.hasTrait(ErrorTrait.self) {
                return base
            } else if shape.type == .intEnum {
                // The NestedShapeTransformer in main codegen inadvertently excludes intEnum
                // so it is not namespaced here.  All other shape types are in the namespace.
                let first = base.first?.uppercased() ?? ""
                return "\(first)\(base.dropFirst())"
            } else {
                let first = base.first?.uppercased() ?? ""
                let capitalized = "\(first)\(base.dropFirst())"
                return try "\(modelNamespace).\(capitalized)"
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
            return "Foundation.Data"
        case .timestamp:
            return "Foundation.Date"
        case .service:
            // Returns the type name for the client
            guard let serviceShape = shape as? ServiceShape else {
                throw SymbolProviderError("Shape has type .service but is not a ServiceShape")
            }
            return try "\(serviceShape.clientBaseName)Client"
        case .document, .member, .operation, .resource:
            throw SymbolProviderError("Cannot provide Swift symbol for shape type \(shape.type)")
        }
    }

    static let locale = Locale(identifier: "en_US_POSIX")

    public func operationMethodName(operation: OperationShape) throws -> String {
        return operation.id.name.toLowerCamelCase()
    }

    public func propertyName(shapeID: ShapeID) throws -> String {
        guard let member = shapeID.member else { throw SymbolProviderError("Shape ID has no member name") }
        return member.toLowerCamelCase()
    }

    public func enumCaseName(shapeID: ShapeID) throws -> String {
        try propertyName(shapeID: shapeID).lowercased()
    }

    private var modelNamespace: String {
        get throws {
            try swiftType(shape: service).appending("Types")
        }
    }
}

extension String {

    func toLowerCamelCase() -> String {
        let words = splitOnWordBoundaries() // Split into words
        let firstWord = words.first!.lowercased() // make first word lowercase
        return firstWord + words.dropFirst().joined() // join lowercased first word to remainder
    }

    func toUpperCamelCase() -> String {
        let words = splitOnWordBoundaries() // Split into words
        let firstLetter = words.first!.first!.uppercased() // make first letter uppercase
        return firstLetter + words.joined().dropFirst() // join uppercased first letter to remainder
    }

    func splitOnWordBoundaries() -> [String] {
        // TODO: when nonsupporting platforms are dropped, convert this to Swift-native regex
        // adapted from Java v2 SDK CodegenNamingUtils.splitOnWordBoundaries
        var result = self

        // all non-alphanumeric characters: "acm-success"-> "acm success"
        result = nonAlphaNumericRegex.stringByReplacingMatches(in: result, range: result.range, withTemplate: " ")

        // if there is an underscore, split on it: "acm_success" -> "acm", "_", "success"
        result = underscoreRegex.stringByReplacingMatches(in: result, range: result.range, withTemplate: " _ ")

        // if a number has a standalone v or V in front of it, separate it out
        result = smallVRegex.stringByReplacingMatches(in: result, range: result.range, withTemplate: "$1 v$2")
        result = largeVRegex.stringByReplacingMatches(in: result, range: result.range, withTemplate: "$1 V$2")

        // add a space between camelCased words
        result = camelCaseSplitRegex.stringByReplacingMatches(in: result, range: result.range, withTemplate: " ")

        // add a space after acronyms
        result = acronymSplitRegex.stringByReplacingMatches(in: result, range: result.range, withTemplate: "$1 $2")

        // add space after a number in the middle of a word
        result = spaceAfterNumberRegex.stringByReplacingMatches(in: result, range: result.range, withTemplate: "$1 $2")

        // remove extra spaces - multiple consecutive ones or those and the beginning/end of words
        result = removeExtraSpaceRegex.stringByReplacingMatches(in: result, range: result.range, withTemplate: " ")
            .trimmingCharacters(in: .whitespaces)

        return result.components(separatedBy: " ")
    }

    var range: NSRange {
        NSRange(location: 0, length: count)
    }
}

// Regexes used in splitOnWordBoundaries() above.
// force_try linter rule is disabled since these are just created from static strings.
// swiftlint:disable force_try
private let nonAlphaNumericRegex = try! NSRegularExpression(pattern: "[^A-Za-z0-9+_]")
private let underscoreRegex = try! NSRegularExpression(pattern: "_")
private let smallVRegex = try! NSRegularExpression(pattern: "([^a-z]{2,})v([0-9]+)")
private let largeVRegex = try! NSRegularExpression(pattern: "([^a-z]{2,})V([0-9]+)")
private let camelCaseSplitRegex = try! NSRegularExpression(pattern: "(?<=[a-z])(?=[A-Z]([a-zA-Z]|[0-9]))")
private let acronymSplitRegex = try! NSRegularExpression(pattern: "([A-Z]+)([A-Z][a-z])")
private let spaceAfterNumberRegex = try! NSRegularExpression(pattern: "([0-9])([a-zA-Z])")
private let removeExtraSpaceRegex = try! NSRegularExpression(pattern: "\\s+")
// swiftlint:enable force_try

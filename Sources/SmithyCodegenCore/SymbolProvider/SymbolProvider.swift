//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Locale
import struct Foundation.NSRange
import class Foundation.NSRegularExpression
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
            guard service.type == .service else {
                throw SymbolProviderError("Called serviceName on non-service shape")
            }
            guard case .object(let serviceInfo) = service.getTrait(.init("aws.api", "service")) else {
                throw SymbolProviderError("No service trait on service")
            }
            guard case .string(let sdkID) = serviceInfo["sdkId"] else {
                throw SymbolProviderError("No sdkId on service trait")
            }
            return sdkID.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "Service", with: "")
        }
    }

    private var inputTraitID = ShapeID("smithy.api", "input")
    private var outputTraitID = ShapeID("smithy.api", "output")
    private var errorTraitID = ShapeID("smithy.api", "error")
    private var operationNameTraitID = ShapeID("swift.synthetic", "operationName")

    public func swiftType(shape: Shape) throws -> String {
        switch shape.type {
        case .structure, .union, .enum, .intEnum:
            if case .string(let name) = shape.getTrait(operationNameTraitID), shape.hasTrait(inputTraitID) {
                return "\(name)Input"
            } else if shape.hasTrait(inputTraitID) {
                guard let operation = model.shapes.values
                    .filter({ $0.type == .operation })
                    .map({ $0 as! OperationShape }) // swiftlint:disable:this force_cast
                    .first(where: { $0.inputShapeID == shape.id })
                else { throw SymbolProviderError("Operation for input \(shape.id) not found") }
                return "\(operation.id.name)Input"
            } else if
                case .string(let name) = shape.getTrait(operationNameTraitID), shape.hasTrait(outputTraitID) {
                return "\(name)Output"
            } else if shape.hasTrait(outputTraitID) {
                guard let operation = model.shapes.values
                    .filter({ $0.type == .operation })
                    .map({ $0 as! OperationShape }) // swiftlint:disable:this force_cast
                    .first(where: { $0.outputShapeID == shape.id })
                else { throw SymbolProviderError("Operation for output \(shape.id) not found") }
                return "\(operation.id.name)Output"
            } else if shape.hasTrait(errorTraitID) {
                return shape.id.name
            } else {
                let orig = shape.id.name
                let first = orig.first?.uppercased() ?? ""
                let capitalized = "\(first)\(orig.dropFirst())"
                return try "\(serviceName)ClientTypes.\(capitalized)"
            }
        case .list, .set:
            guard let listShape = shape as? ListShape else {
                throw SymbolProviderError("Shape has type .list but is not a ListShape")
            }
            let elementType = try swiftType(shape: listShape.member.target)
            return "[\(elementType)]"
        case .map:
            guard let mapShape = shape as? MapShape else {
                throw SymbolProviderError("Shape has type .map but is not a MapShape")
            }
            let valueType = try swiftType(shape: mapShape.value.target)
            return "[String: \(valueType)]"
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
        case .document, .member, .service, .operation, .resource:
            throw SymbolProviderError("Cannot provide Swift symbol for shape type \(shape.type)")
        }
    }

    static let locale = Locale(identifier: "en_US_POSIX")

    public func propertyName(shapeID: ShapeID) throws -> String {
        guard let member = shapeID.member else { throw SymbolProviderError("Shape ID has no member name") }
        return member.toLowerCamelCase()
    }

    public func enumCaseName(shapeID: ShapeID) throws -> String {
        try propertyName(shapeID: shapeID).toLowerCamelCase().lowercased()
    }
}

private extension String {

    func toLowerCamelCase() -> String {
        let words = splitOnWordBoundaries() // Split into words
        let firstWord = words.first!.lowercased() // make first word lowercase
        return firstWord + words.dropFirst().joined() // join lowercased first word to remainder
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

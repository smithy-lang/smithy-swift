//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import struct Smithy.ShapeID

public struct SymbolProvider {
    let model: Model

    init(model: Model) {
        self.model = model
    }

    func serviceName(service: Shape) -> String {
        guard service.type == .service else { fatalError("Called serviceName on non-service shape") }
        guard case .object(let serviceInfo) = service.getTrait(.init("aws.api", "service")) else { fatalError("No service trait on service") }
        guard case .string(let sdkID) = serviceInfo["sdkId"] else { fatalError("No sdkId on service trait") }
        return sdkID.replacingOccurrences(of: " ", with: "").replacingOccurrences(of: "Service", with: "")
    }

    func swiftType(shape: Shape) -> String {
        if case .string(let name) = shape.getTrait(.init("swift.synthetic", "operationName")), shape.hasTrait(.init("smithy.api", "input")) {
            return name + "Input"
        } else if shape.hasTrait(.init("smithy.api", "input")) {
            guard let operation = model.shapes.values
                .filter({ $0.type == .operation })
                .map({ $0 as! OperationShape })
                .first(where: { $0.inputShapeID == shape.id }) else { fatalError("Operation for input \(shape.id) not found") }
            return operation.id.name + "Input"
        } else if case .string(let name) = shape.getTrait(.init("swift.synthetic", "operationName")), shape.hasTrait(.init("smithy.api", "output")){
            return name + "Output"
        } else if shape.hasTrait(.init("smithy.api", "output")) {
            guard let operation = model.shapes.values
                .filter({ $0.type == .operation })
                .map({ $0 as! OperationShape })
                .first(where: { $0.outputShapeID == shape.id }) else { fatalError("Operation for output \(shape.id) not found") }
            return operation.id.name + "Output"
        } else if shape.hasTrait(.init("smithy.api", "error")) {
            return shape.id.name
        } else {
            guard let service = model.shapes.values.first(where: { $0.type == .service }) else { fatalError("service not found") }
            return serviceName(service: service) + "ClientTypes." + shape.id.name
        }
    }

    func methodName(shapeID: ShapeID) -> String {
        guard let member = shapeID.member else { fatalError("Shape ID has no member name") }
        return member.toLowerCamelCase()
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
        let nonAlphaNumericRegex = try! NSRegularExpression(pattern: "[^A-Za-z0-9+_]")
        result = nonAlphaNumericRegex.stringByReplacingMatches(in: result, range: NSRange(location: 0, length: result.count), withTemplate: " ")

        // if there is an underscore, split on it: "acm_success" -> "acm", "_", "success"
        let underscoreRegex = try! NSRegularExpression(pattern: "_")
        result = underscoreRegex.stringByReplacingMatches(in: result, range: NSRange(location: 0, length: result.count), withTemplate: " _ ")

        // if a number has a standalone v or V in front of it, separate it out
        let smallVRegex = try! NSRegularExpression(pattern: "([^a-z]{2,})v([0-9]+)")
        result = smallVRegex.stringByReplacingMatches(in: result, range: NSRange(location: 0, length: result.count), withTemplate: "$1 v$2")

        let largeVRegex = try! NSRegularExpression(pattern: "([^a-z]{2,})V([0-9]+)")
        result = largeVRegex.stringByReplacingMatches(in: result, range: NSRange(location: 0, length: result.count), withTemplate: "$1 V$2")

        // add a space between camelCased words
        let camelCaseSplitRegex = try! NSRegularExpression(pattern: "(?<=[a-z])(?=[A-Z]([a-zA-Z]|[0-9]))")
        result = camelCaseSplitRegex.stringByReplacingMatches(in: result, range: NSRange(location: 0, length: result.count), withTemplate: " ")

        // add a space after acronyms
        let acronymSplitRegex = try! NSRegularExpression(pattern: "([A-Z]+)([A-Z][a-z])")
        result = acronymSplitRegex.stringByReplacingMatches(in: result, range: NSRange(location: 0, length: result.count), withTemplate: "$1 $2")

        // add space after a number in the middle of a word
        let spaceAfterNumberRegex = try! NSRegularExpression(pattern: "([0-9])([a-zA-Z])")
        result = spaceAfterNumberRegex.stringByReplacingMatches(in: result, range: NSRange(location: 0, length: result.count), withTemplate: "$1 $2")

        // remove extra spaces - multiple consecutive ones or those and the beginning/end of words
        let removeExtraSpaceRegex = try! NSRegularExpression(pattern: "\\s+")
        result = removeExtraSpaceRegex.stringByReplacingMatches(in: result, range: NSRange(location: 0, length: result.count), withTemplate: " ").trimmingCharacters(in: .whitespaces)

        return result.components(separatedBy: " ")
    }
}

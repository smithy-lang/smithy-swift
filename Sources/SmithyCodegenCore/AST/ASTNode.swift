//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Contains the value of a Smithy Node, as used in a JSON AST.
///
/// Smithy node data is basically the same as the data that can be stored in JSON.
/// The root of a Smithy node may be of any type, i.e. unlike JSON, the root element is not limited to object or list.
///
/// See the definition of node value in the Smithy spec: https://smithy.io/2.0/spec/model.html#node-values
enum ASTNode: Sendable {
    case object([String: ASTNode])
    case list([ASTNode])
    case string(String)
    case number(Double)
    case boolean(Bool)
    case null
}

extension ASTNode: Decodable {

    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .boolean(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .number(Double(int))
        } else if let double = try? container.decode(Double.self) {
            self = .number(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([ASTNode].self) {
            self = .list(array)
        } else if let dictionary = try? container.decode([String: ASTNode].self) {
            self = .object(dictionary)
        } else {
            throw ASTError("Undecodable value in AST node")
        }
    }
}

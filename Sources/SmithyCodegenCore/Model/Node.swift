//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Contains the value of a Smithy Node.
///
/// Smithy node data is basically the same as the data that can be stored in JSON.
/// The root of a Smithy node may be of any type, i.e. unlike JSON, the root element is not limited to object or list.
///
/// See the definition of node value in the Smithy spec: https://smithy.io/2.0/spec/model.html#node-values
public enum Node: Sendable {
    case object([String: Node])
    case list([Node])
    case string(String)
    case number(Double)
    case boolean(Bool)
    case null
}

extension ASTNode {
    
    /// Creates a model Node from a AST-specific ASTNode.
    var modelNode: Node {
        switch self {
        case .object(let object):
            return .object(object.mapValues { $0.modelNode })
        case .list(let list):
            return .list(list.map { $0.modelNode })
        case .string(let value):
            return .string(value)
        case .number(let value):
            return .number(value)
        case .boolean(let value):
            return .boolean(value)
        case .null:
            return .null
        }
    }
}

extension Node {

    var rendered: String {
        switch self {
        case .object(let object):
            guard !object.isEmpty else { return "[:]" }
            return "[" + object.map { "\($0.key.literal): \($0.value.rendered)" }.joined(separator: ",") + "]"
        case .list(let list):
            return "[" + list.map { $0.rendered }.joined(separator: ", ") + "]"
        case .string(let string):
            return string.literal
        case .number(let number):
            return "\(number)"
        case .boolean(let bool):
            return "\(bool)"
        case .null:
            return "nil"
        }
    }
}

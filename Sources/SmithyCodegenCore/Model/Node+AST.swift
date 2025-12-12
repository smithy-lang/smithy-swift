//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Node

extension ASTNode {

    /// Creates a Smithy Node from a AST-specific ASTNode.
    var node: Smithy.Node {
        switch self {
        case .object(let object):
            return .object(object.mapValues { $0.node })
        case .list(let list):
            return .list(list.map { $0.node })
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

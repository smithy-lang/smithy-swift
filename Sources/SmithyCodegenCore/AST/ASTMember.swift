//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.Node

// See https://smithy.io/2.0/spec/json-ast.html#ast-member
struct ASTMember: Decodable {
    let target: String
    let traits: [String: Node]?
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// See https://smithy.io/2.0/spec/json-ast.html#ast-shape-reference
struct ASTReference: Decodable {
    let target: String
}

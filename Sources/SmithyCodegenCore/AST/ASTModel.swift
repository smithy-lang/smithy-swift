//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// See https://smithy.io/2.0/spec/json-ast.html#top-level-properties
struct ASTModel: Decodable {
    let smithy: String
    let metadata: ASTNode?
    let shapes: [String: ASTShape]
}

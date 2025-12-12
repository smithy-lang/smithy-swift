//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

// See https://smithy.io/2.0/spec/json-ast.html#json-ast
// This Swift type captures fields for all AST shape types
struct ASTShape: Decodable {
    let type: ASTType
    let traits: [String: ASTNode]?
    let member: ASTMember?
    let key: ASTMember?
    let value: ASTMember?
    let members: [String: ASTMember]?
    let version: String?
    let operations: [ASTReference]?
    let resources: [ASTReference]?
    let errors: [ASTReference]?
    let rename: [String: String]?
    let identifiers: [String: ASTReference]?
    let properties: [String: ASTReference]?
    let create: ASTReference?
    let put: ASTReference?
    let read: ASTReference?
    let update: ASTReference?
    let delete: ASTReference?
    let list: ASTReference?
    let collectionOperations: [ASTReference]?
    let input: ASTReference?
    let output: ASTReference?
}

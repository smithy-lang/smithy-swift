//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

struct ASTMember: Decodable {
    let target: String
    let traits: [String: ASTNode]?
}

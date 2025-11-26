//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

struct ASTModel: Decodable {
    let smithy: String
    let metadata: ASTNode?
    let shapes: [String: ASTShape]
}

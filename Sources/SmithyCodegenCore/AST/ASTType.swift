//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

enum ASTType: String, Decodable {
    // These cases are all the Smithy shape types
    case blob
    case boolean
    case string
    case timestamp
    case byte
    case short
    case integer
    case long
    case float
    case document
    case double
    case bigDecimal
    case bigInteger
    case `enum`
    case intEnum
    case list
    case set
    case map
    case structure
    case union
    case member
    case service
    case resource
    case operation

    // Special for AST, added 'apply' case
    case apply
}

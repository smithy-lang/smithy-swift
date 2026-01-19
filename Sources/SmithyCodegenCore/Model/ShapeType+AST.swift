//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import enum Smithy.ShapeType

extension ASTType {

    var modelType: ShapeType {
        get throws {
            switch self {
            case .blob:
                return .blob
            case .boolean:
                return .boolean
            case .string:
                return .string
            case .timestamp:
                return .timestamp
            case .byte:
                return .byte
            case .short:
                return .short
            case .integer:
                return .integer
            case .long:
                return .long
            case .float:
                return .float
            case .document:
                return .document
            case .double:
                return .double
            case .bigDecimal:
                return .bigDecimal
            case .bigInteger:
                return .bigInteger
            case .`enum`:
                return .`enum`
            case .intEnum:
                return .intEnum
            case .list:
                return .list
            case .set:
                return .set
            case .map:
                return .map
            case .structure:
                return .structure
            case .union:
                return .union
            case .member:
                return .member
            case .service:
                return .service
            case .resource:
                return .resource
            case .operation:
                return .operation
            case .apply:
                throw ModelError("\"apply\" AST shapes not implemented")
            }
        }
    }
}

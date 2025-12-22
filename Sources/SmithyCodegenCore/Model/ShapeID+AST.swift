//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.ShapeID

extension ASTReference {

    var id: ShapeID {
        get throws {
            return try ShapeID(target)
        }
    }
}

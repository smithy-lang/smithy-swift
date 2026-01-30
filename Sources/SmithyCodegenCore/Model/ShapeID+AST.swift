//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.ShapeID

extension ASTReference {
    
    /// Convenience accessor to create a ``ShapeID`` from an ``ASTReference``.
    var id: ShapeID {
        get throws {
            try ShapeID(target)
        }
    }
}

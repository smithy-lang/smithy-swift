//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.ShapeID

extension ASTReference {

    var id: ShapeID {
        do {
            return try ShapeID(target)
        } catch {
            fatalError("Creation of ShapeID from ASTReference failed: \(error.localizedDescription)")
        }
    }
}

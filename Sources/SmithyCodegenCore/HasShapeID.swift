//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.ShapeID

protocol HasShapeID {
    var id: ShapeID { get }
}

extension Array where Element: HasShapeID {

    /// Sorts alphabetically by shape ID to match the ordering used by Kotlin-based codegen.
    ///
    /// The comparator on `ShapeID` implements the actual comparison logic.
    /// - Returns: An array of elements in sorted order
    func smithySorted() -> Self {
        sorted { $0.id < $1.id }
    }
}

extension ShapeID: HasShapeID {

    var id: ShapeID {
        self
    }
}

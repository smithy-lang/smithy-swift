//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Foundation.DateFormatter
import struct Foundation.Locale

extension Model {

    /// Removes all shapes with the `deprecated` trait and a `since` date after `2024-09-17`, the `aws-sdk-swift`
    /// GA date.
    /// - Returns: The transformed model.
    func withDeprecatedShapesRemoved() throws -> Model {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"

        // The "cutoff date".  Shapes deprecated before this date will be removed from the model.
        let cutoff = formatter.date(from: "2024-09-17")!

        // Filter the deprecated shapes from the model.
        let nonDeprecatedShapes = try shapes.filter { (_, shape) in

            // Keep this shape if it doesn't have a DeprecatedTrait with a `since` value.
            guard let since = try shape.getTrait(DeprecatedTrait.self)?.since else { return true }

            // Keep this shape if the `since` value doesn't parse to a yyyy-MM-dd date.
            guard let sinceDate = formatter.date(from: since) else { return true }

            // Compare dates, keep the shape if it was deprecated before the cutoff.
            return sinceDate > cutoff
        }

        // Trim references to the removed shapes before returning
        return try Model(version: version, metadata: metadata, shapes: nonDeprecatedShapes).trimReferences()
    }
}

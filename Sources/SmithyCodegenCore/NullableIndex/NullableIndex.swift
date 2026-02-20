//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Smithy.AddedDefaultTrait
import struct Smithy.ClientOptionalTrait
import struct Smithy.DefaultTrait
import struct Smithy.InputTrait
import struct Smithy.ShapeID
import enum Smithy.ShapeType
import struct Smithy.SparseTrait

struct NullableIndex {

    /// Determines whether a structure member should be rendered as non-optional.
    /// - Parameter memberShape: The member for which optionality is being determined
    /// - Returns: `true` if the member should be non-optional, `false` otherwise
    func isNonOptional(_ memberShape: MemberShape) throws -> Bool {
        let container = try memberShape.container
        let target = try memberShape.target

        // Note that these are the current rules in use by smithy-swift.  They are not Smithy 2.0 "correct".

        // If the container is a list/set, member is nonoptional unless sparse trait is applied
        if [ShapeType.list, .set].contains(container.type), memberShape.id.member == "member" {
            return !container.hasTrait(SparseTrait.self)
        }

        // If the container is a map, value is nonoptional unless sparse trait is applied
        if container.type == .map {
            if memberShape.id.member == "value" {
                return !container.hasTrait(SparseTrait.self)
            } else {
                // key is always non-optional
                return true
            }
        }

        // If the containing shape has the input trait, it's definitely optional
        if container.hasTrait(InputTrait.self) {
            return false
        }

        // If the member has the clientOptional trait, it's definitely optional
        if memberShape.hasTrait(ClientOptionalTrait.self) {
            return false
        }

        // If the member has the addedDefault trait, it's definitely optional
        if memberShape.hasTrait(AddedDefaultTrait.self) {
            return false
        }

        // Only number & Boolean types are allowed to be non-optional
        let allowedTypes =
            [ShapeType.boolean, .bigDecimal, .bigInteger, .byte, .double, .float, .intEnum, .integer, .long, .short]
        guard allowedTypes.contains(target.type) else { return false }

        // Check if there is a default trait with a zero/false value.  If so, member is non-optional.
        let memberDefaultTrait = try memberShape.getTrait(DefaultTrait.self)
        let targetDefaultTrait = try target.getTrait(DefaultTrait.self)
        guard let defaultNode = (memberDefaultTrait ?? targetDefaultTrait)?.node else {
            return false
        }
        if target.type == .boolean, let bool = defaultNode.boolean, !bool {
            return true
        } else if let number = defaultNode.number, number == 0.0 {
            return true
        } else {
            return false
        }
    }
}

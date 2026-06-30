//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
import struct Smithy.ShapeID
@_spi(SchemaBasedSerde)
import protocol Smithy.Trait

/// The trait IDs that are used at codegen time only.
///
/// These will only be present on shapes at codegen time, and not copied into schemas
/// for runtime use.  This list can be expanded as features are added to Smithy/SDK that use them.
@_spi(SchemaBasedSerde)
public let allCodegenTraitIDs = Set(allCodegenTraitTypes.keys)

@_spi(SchemaBasedSerde)
public func codegenTraitType(for traitID: ShapeID) -> (any Trait.Type)? {
    allCodegenTraitTypes[traitID]
}

let allCodegenTraitTypes: [ShapeID: any Trait.Type] = [
    DeprecatedTrait.id: DeprecatedTrait.self,
    EnumTrait.id: EnumTrait.self,
    UsedAsInputTrait.id: UsedAsInputTrait.self,
    UsedAsOutputTrait.id: UsedAsOutputTrait.self,
]

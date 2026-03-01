//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// The trait IDs that should be copied into schemas.  Other traits are omitted for brevity.
///
/// This list can be expanded as features are added to Smithy/SDK that use them.
public let allSupportedTraitIDs = Set(allSupportedTraitTypes.keys)

public func traitType(for traitID: ShapeID) -> (any Trait.Type)? {
    allSupportedTraitTypes[traitID]
}

private let allSupportedTraitTypes: [ShapeID: any Trait.Type] = [
    // Traits defined in Smithy
    ServiceTrait.id: ServiceTrait.self,
    AddedDefaultTrait.id: AddedDefaultTrait.self,
    AWSQueryCompatibleTrait.id: AWSQueryCompatibleTrait.self,
    AWSQueryErrorTrait.id: AWSQueryErrorTrait.self,
    ClientOptionalTrait.id: ClientOptionalTrait.self,
    DefaultTrait.id: DefaultTrait.self,
    EnumValueTrait.id: EnumValueTrait.self,
    ErrorTrait.id: ErrorTrait.self,
    InputTrait.id: InputTrait.self,
    OutputTrait.id: OutputTrait.self,
    RequiredTrait.id: RequiredTrait.self,
    SensitiveTrait.id: SensitiveTrait.self,
    SparseTrait.id: SparseTrait.self,
    TimestampFormatTrait.id: TimestampFormatTrait.self,
    UnitTypeTrait.id: UnitTypeTrait.self, // UnitTypeTrait will only ever appear in Prelude.unitSchema

    // Synthetic traits
    TargetsUnitTrait.id: TargetsUnitTrait.self,
]

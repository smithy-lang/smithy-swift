//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// The trait IDs that should be copied into schemas.  Other traits are omitted for brevity.
///
/// This list can be expanded as features are added to Smithy/SDK that use them.
public let allSupportedTraits = Set([

    // Traits defined in Smithy
    ServiceTrait.id,
    AddedDefaultTrait.id,
    AWSQueryCompatibleTrait.id,
    AWSQueryErrorTrait.id,
    ClientOptionalTrait.id,
    DefaultTrait.id,
    EnumValueTrait.id,
    ErrorTrait.id,
    InputTrait.id,
    OutputTrait.id,
    RequiredTrait.id,
    SensitiveTrait.id,
    SparseTrait.id,
    TimestampFormatTrait.id,
    UnitTypeTrait.id, // UnitTypeTrait will only ever appear in Prelude.unitSchema

    // Synthetic traits
    TargetsUnitTrait.id,
])

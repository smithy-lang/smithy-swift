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
    ServiceTrait.id,
    AddedDefaultTrait.id,
    AWSQueryCompatibleTrait.id,
    AWSQueryErrorTrait.id,
    SparseTrait.id,
    ClientOptionalTrait.id,
    InputTrait.id,
    OutputTrait.id,
    ErrorTrait.id,
    DefaultTrait.id,
    SensitiveTrait.id,

    // Synthetic traits
    TargetsUnitTrait.id,
])

// Not used at runtime so not included here:
// - DeprecatedTrait
// - EnumTrait
// - StreamingTrait

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
public let allRuntimeTraitTypes: [any Trait.Type] = [
    // Traits defined in Smithy
    ServiceTrait.self,
    AddedDefaultTrait.self,
    AWSQueryCompatibleTrait.self,
    AWSQueryErrorTrait.self,
    ClientOptionalTrait.self,
    DefaultTrait.self,
    EnumValueTrait.self,
    ErrorTrait.self,
    EventHeaderTrait.self,
    EventPayloadTrait.self,
    HTTPLabelTrait.self,
    HTTPQueryTrait.self,
    HTTPTrait.self,
    InputTrait.self,
    JSONNameTrait.self,
    OutputTrait.self,
    RequiredTrait.self,
    SensitiveTrait.self,
    SparseTrait.self,
    StreamingTrait.self,
    TimestampFormatTrait.self,
    UnitTypeTrait.self, // UnitTypeTrait will only ever appear in Prelude.unitSchema

    // Synthetic traits
    TargetsUnitTrait.self,
]

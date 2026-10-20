//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SchemaBasedSerde)
import var Smithy.allRuntimeTraitTypes
@_spi(SchemaBasedSerde)
import protocol Smithy.Trait

let allCodegenTraitTypes: [any Trait.Type] = [
    DeprecatedTrait.self,
    EnumTrait.self,
    UsedAsInputTrait.self,
    UsedAsOutputTrait.self,
]

/// This list is a combination of the runtime traits defined in Smithy and the codegen time traits defined in this module.
/// It serves as the default when loading a Smithy model.
let builtinTraitTypes: [any Trait.Type] = Array(allRuntimeTraitTypes) + Array(allCodegenTraitTypes)

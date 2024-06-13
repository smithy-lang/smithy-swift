/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.steps

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.OperationStep
import software.amazon.smithy.swift.codegen.SwiftDependency

class OperationSerializeStep(
    inputType: Symbol,
    outputType: Symbol,
    outputErrorType: Symbol
) : OperationStep(outputType, outputErrorType) {
    override val inputType: Symbol = Symbol.builder()
        .name("SerializeStepInput<$inputType>")
        .namespace("ClientRuntime", ".")
        .addReference(inputType)
        .dependencies(SwiftDependency.CLIENT_RUNTIME)
        .build()
}

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes

abstract class OperationStep(outputType: Symbol, outputErrorType: Symbol) {
    abstract val inputType: Symbol
    val outputType: Symbol = Symbol.builder()
        .name("${ClientRuntimeTypes.Middleware.OperationOutput}<$outputType>")
        .addReference(ClientRuntimeTypes.Middleware.OperationOutput)
        .addReference(outputType)
        .build()

    val errorType: Symbol = Symbol
        .builder()
        .name(outputErrorType.name)
        .build()
}

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.Symbol

abstract class OperationStep(outputType: Symbol, outputErrorType: Symbol) {
    abstract val inputType: Symbol
    val outputType: Symbol = Symbol
        .builder()
        .name("${ClientRuntimeTypes.Middleware.OperationOutput}<$outputType>")
        .addDependency(SwiftDependency.CLIENT_RUNTIME)
        .build()

    val errorType: Symbol = Symbol
        .builder()
        .name("${ClientRuntimeTypes.Core.SdkError}<$outputErrorType>")
        .addDependency(SwiftDependency.CLIENT_RUNTIME)
        .build()
}

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.protocoltests.traits.HttpRequestTestCase
import software.amazon.smithy.swift.codegen.SwiftWriter

interface HTTPProtocolCustomizable {

    fun renderInternals(ctx: ProtocolGenerator.GenerationContext) {
        // Default implementation is no-op
    }

    fun renderContextAttributes(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        serviceShape: ServiceShape,
        op: OperationShape
    ) {
        // Default implementation is no-op
    }

    fun renderEventStreamAttributes(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape
    )

    fun serviceClient(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        serviceConfig: ServiceConfig
    ): HttpProtocolServiceClient

    fun customRenderBodyComparison(test: HttpRequestTestCase): ((SwiftWriter, HttpRequestTestCase, Symbol, Shape, String, String) -> Unit)? {
        return null
    }

    fun alwaysHasHttpBody(): Boolean {
        return false
    }

    interface ServiceErrorCustomRenderer {
        fun render(writer: SwiftWriter)
    }

    fun serviceErrorCustomRenderer(ctx: ProtocolGenerator.GenerationContext): ServiceErrorCustomRenderer? {
        return null
    }

    val baseErrorSymbol: Symbol

    val unknownServiceErrorSymbol: Symbol

    val defaultTimestampFormat: TimestampFormatTrait.Format
}

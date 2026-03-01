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
import software.amazon.smithy.swift.codegen.swiftmodules.RPCv2CBORTypes

interface HTTPProtocolCustomizable {
    fun renderInternals(ctx: ProtocolGenerator.GenerationContext) {
        // Default implementation is no-op
    }

    fun renderContextAttributes(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        serviceShape: ServiceShape,
        op: OperationShape,
    ) {
        // Default implementation is no-op
    }

    fun renderEventStreamAttributes(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape,
    )

    fun serviceClient(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        serviceConfig: ServiceConfig,
    ): HttpProtocolServiceClient

    fun customRenderBodyComparison(
        test: HttpRequestTestCase,
    ): ((SwiftWriter, HttpRequestTestCase, Symbol, Shape, String, String) -> Unit)? = null

    fun alwaysHasHttpBody(): Boolean = false

    interface ServiceErrorCustomRenderer {
        fun render(writer: SwiftWriter)
    }

    val clientProtocolSymbol: Symbol
        get() = RPCv2CBORTypes.HTTPClientProtocol

    val plugins: List<Plugin>
        get() = listOf()

    fun serviceErrorCustomRenderer(ctx: ProtocolGenerator.GenerationContext): ServiceErrorCustomRenderer? = null

    val endpointMiddlewareSymbol: Symbol

    val baseErrorSymbol: Symbol

    val queryCompatibleUtilsSymbol: Symbol

    val unknownServiceErrorSymbol: Symbol

    val defaultTimestampFormat: TimestampFormatTrait.Format

    fun smokeTestGenerator(ctx: ProtocolGenerator.GenerationContext): SmokeTestGenerator
}

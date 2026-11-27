/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.aws.protocols.ec2query

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.protocoltests.traits.HttpRequestTestCase
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.DefaultHTTPProtocolCustomizations
import software.amazon.smithy.swift.codegen.integration.Plugin
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyEC2QueryTypes

open class EC2QueryCustomizations : DefaultHTTPProtocolCustomizations() {
    override fun customRenderBodyComparison(
        test: HttpRequestTestCase,
    ): ((SwiftWriter, HttpRequestTestCase, Symbol, Shape, String, String) -> Unit)? = this::renderFormURLBodyComparison

    private fun renderFormURLBodyComparison(
        writer: SwiftWriter,
        test: HttpRequestTestCase,
        symbol: Symbol,
        shape: Shape,
        expectedData: String,
        actualData: String,
    ) {
        writer.write("self.assertEqualFormURLBody($expectedData, $actualData)")
    }

    override fun alwaysHasHttpBody(): Boolean = true

    override val baseErrorSymbol: Symbol = ClientRuntimeTypes.EC2Query.EC2QueryError

    override val defaultTimestampFormat: TimestampFormatTrait.Format = TimestampFormatTrait.Format.DATE_TIME

    override val plugins: List<Plugin> = listOf(EC2QueryPlugin())

    // Every ec2Query request carries the service's version.
    override fun renderClientProtocol(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
    ): String = writer.format("\$N(version: \$S)", SmithyEC2QueryTypes.HTTPClientProtocol, ctx.service.version)
}

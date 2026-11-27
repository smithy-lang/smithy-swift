/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.aws.protocols.restxml

import software.amazon.smithy.aws.traits.protocols.RestXmlTrait
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.DefaultHTTPProtocolCustomizations
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.getTrait
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyRestXMLTypes

open class RestXmlCustomizations : DefaultHTTPProtocolCustomizations() {
    override val baseErrorSymbol: Symbol = ClientRuntimeTypes.RestXML.RestXMLError

    // Error responses are unwrapped when the service's restXml trait sets noErrorWrapping.
    override fun renderClientProtocol(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
    ): String =
        if (ctx.service.getTrait<RestXmlTrait>()?.isNoErrorWrapping == true) {
            writer.format("\$N(noErrorWrapping: true)", SmithyRestXMLTypes.HTTPClientProtocol)
        } else {
            writer.format("\$N()", SmithyRestXMLTypes.HTTPClientProtocol)
        }
}

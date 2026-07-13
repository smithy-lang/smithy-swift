/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.aws.protocols.restjson

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.DefaultHTTPProtocolCustomizations
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyRestJson1Types

open class RestJson1Customizations : DefaultHTTPProtocolCustomizations() {
    override val baseErrorSymbol: Symbol = ClientRuntimeTypes.RestJSON.RestJSONError

    override fun renderClientProtocol(writer: SwiftWriter): String = writer.format("\$N()", SmithyRestJson1Types.HTTPClientProtocol)
}

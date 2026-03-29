/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.aws.protocols.awsjson

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.DefaultHTTPProtocolCustomizations
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyAWSJSONTypes

open class AWSJSONCustomizations(
    private val version: String,
) : DefaultHTTPProtocolCustomizations() {
    override val baseErrorSymbol: Symbol = ClientRuntimeTypes.AWSJSON.AWSJSONError

    override val defaultTimestampFormat = TimestampFormatTrait.Format.EPOCH_SECONDS

    override fun renderClientProtocol(writer: SwiftWriter): String =
        writer.format("\$N(version: .v$version)", SmithyAWSJSONTypes.HTTPClientProtocol)
}

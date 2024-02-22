/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.model.buildSymbol
import software.amazon.smithy.swift.codegen.utils.toUpperCamelCase

/**
 * Represents a config field on a client config struct.
 */
data class ConfigField(val memberName: String?, val type: Symbol, val propFormatter: String = "\$N", private val documentation: String? = null, val paramFormatter: String = "\$D")

/**
 * ServiceConfig abstract class that allows configuration customizations to be configured for the protocol client generator
 */
abstract class ServiceConfig(val writer: SwiftWriter, val clientName: String, val serviceName: String) {

    open val typeName: String = "${clientName.toUpperCamelCase()}.${clientName.toUpperCamelCase()}Configuration"

    open fun serviceSpecificConfigProperties(): List<ConfigField> = listOf()
}

package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.utils.ToSmithyBuilder

/**
 * Represents a config field on a client config struct.
 */
data class ConfigField(val name: String?, val type: String, private val documentation: String?)
/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftWriter

/**
 * ClientProperty interface to pass in properties to be instantiated in the service client
 */
interface ClientProperty {
    // the name of the client property
    val name: String

    // flag that controls whether renderConfigure() needs called
    val needsConfigure: Boolean
        get() = true

    /**
     * Instantiate the service client property
     *
     * Example
     * ```
     * let encoder: JSONEncoder = JSONEncoder()
     * ```
     */
    fun renderInstantiation(writer: SwiftWriter) {}

    /**
     * Render the configuration needed post instantiation of a service client property
     *
     * Example
     * ```
     * encoder.outputFormatting = .sortedKeys
     * encoder.dateEncodingStrategy = .iso8601
     * encoder.dataEncodingStrategy = .base64
     * encoder.keyEncodingStrategy = .convertToSnakeCase
     * ```
     */
    fun renderConfiguration(writer: SwiftWriter) {}

    /**
     * Render the initialization of a service client property inside the service class
     *
     * Example
     * ```
     * self.encoder = config.encoder ?? encoder
     * self.decoder = config.decoder ?? decoder
     * ```
     */
    fun renderInitialization(writer: SwiftWriter, nameOfConfigObject: String) {}

    /**
     * Register any imports or dependencies that will be needed to use this property at runtime
     */
    fun addImportsAndDependencies(writer: SwiftWriter) {}
}

/**
 * `HttpRequestEncoder` property to help instantiate RequestEncoder
 * @property requestEncoderName The name of the request encoder (e.g. JSONEncoder)
 * @property requestEncoderOptions Map of options to set on the request encoder instance
 */
abstract class HttpRequestEncoder(private val requestEncoder: Symbol, private val requestEncoderOptions: MutableMap<String, String> = mutableMapOf()) : ClientProperty {
    override val name: String = "encoder"
    override fun renderInstantiation(writer: SwiftWriter) {
        writer.write("let \$L = \$N()", name, requestEncoder)
    }

    override fun renderConfiguration(writer: SwiftWriter) {
        requestEncoderOptions.forEach {
            requestEncoderOptionName, requestEncoderOptionValue ->
            writer.write("encoder.$requestEncoderOptionName = $requestEncoderOptionValue")
        }
    }

    override fun renderInitialization(writer: SwiftWriter, nameOfConfigObject: String) {
        writer.write("self.encoder = \$L", name)
    }
}

/**
 * `HttpRequestDecoder` property to help instantiate RequestDecoder
 * @property requestDecoderName The name of the request decoder (e.g. JSONDecoder)
 * @property requestDecoderOptions Map of options to set on the request decoder instance
 */
abstract class HttpResponseDecoder(private val requestDecoder: Symbol, private val requestDecoderOptions: MutableMap<String, String> = mutableMapOf()) : ClientProperty {
    override val name: String = "decoder"
    override fun renderInstantiation(writer: SwiftWriter) {
        writer.write("let \$L = \$N()", name, requestDecoder)
    }

    override fun renderConfiguration(writer: SwiftWriter) {
        requestDecoderOptions.forEach {
            requestDecoderOptionName, requestDecoderOptionValue ->
            writer.write("decoder.$requestDecoderOptionName = $requestDecoderOptionValue")
        }
    }

    override fun renderInitialization(writer: SwiftWriter, nameOfConfigObject: String) {
        writer.write("self.decoder = \$L", name)
    }
}

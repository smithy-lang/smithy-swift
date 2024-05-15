/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration

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

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.build.FileManifest
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.codegen.core.SymbolReference
import software.amazon.smithy.codegen.core.WriterDelegator
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.model.SymbolProperty
import software.amazon.smithy.swift.codegen.model.defaultValue
import software.amazon.smithy.swift.codegen.model.isBoxed
import software.amazon.smithy.swift.codegen.utils.ModelFileUtils

/**
 * Manages writers for Swift files.
 */
class SwiftDelegator(
    private val settings: SwiftSettings,
    private val model: Model,
    private val fileManifest: FileManifest,
    private val symbolProvider: SymbolProvider,
    private val integrations: List<SwiftIntegration> = listOf()
) : WriterDelegator<SwiftWriter>(
    fileManifest,
    symbolProvider,
    SwiftWriter.SwiftWriterFactory(integrations, settings)
) {

    /**
     * Gets a previously created writer or creates a new one if needed.
     *
     * @param shape Shape to create the writer for.
     * @param writerConsumer Consumer that accepts and works with the file.
     */
    fun useShapeWriter(
        shape: Shape?,
        writerConsumer: (SwiftWriter) -> Unit
    ) {
        val symbol = symbolProvider.toSymbol(shape)
        useShapeWriter(symbol, writerConsumer)
    }

    /**
     * Gets a previously created writer or creates a new one if needed.
     *
     * @param symbol Symbol to create the writer for.
     * @param block Lambda that accepts and works with the file.
     */
    fun useShapeWriter(
        symbol: Symbol,
        block: (SwiftWriter) -> Unit
    ) {
        useFileWriter(symbol.definitionFile) { writer ->

            // Add any needed DECLARE symbols.
            writer.addImportReferences(symbol, SymbolReference.ContextOption.DECLARE)
            symbol.dependencies.forEach { writer.addDependency(it) }
            writer.pushState()

            // shape is stored in the property bag when generated, if it's there pull it back out
            val shape = symbol.getProperty("shape", Shape::class.java)
            if (shape.isPresent) {
                // Allow integrations to do things like add onSection callbacks.
                // these onSection callbacks are removed when popState is called.
                for (integration in integrations) {
                    integration.onShapeWriterUse(settings, model, symbolProvider, writer, shape.get())
                }
            }
            block(writer)
            writer.popState()
        }
    }

    fun useShapeExtensionWriter(shape: Shape, extensionName: String, block: (SwiftWriter) -> Unit) {
        val symbol = symbolProvider.toSymbol(shape)
        val baseFilename = "${symbol.name}+$extensionName"
        val filename = ModelFileUtils.filename(settings, baseFilename)
        val extensionSymbol = Symbol.builder()
            .name(symbol.name)
            .definitionFile(filename)
            .putProperty(SymbolProperty.BOXED_KEY, symbol.isBoxed())
            .putProperty("defaultValue", symbol.defaultValue())
            .build()

        useShapeWriter(extensionSymbol, block)
    }

    /**
     * Gets a previously created test file writer or creates a new one if needed
     * and adds a new line if the writer already exists.
     *
     * @param filename Name of the file to create.
     * @param block Lambda that accepts and works with the file.
     */
    fun useTestFileWriter(filename: String, namespace: String, block: (SwiftWriter) -> Unit) {
        useFileWriter(filename, namespace, block)
    }
}

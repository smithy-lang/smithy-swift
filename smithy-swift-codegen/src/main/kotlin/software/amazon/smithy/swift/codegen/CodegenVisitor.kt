/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.build.FileManifest
import software.amazon.smithy.build.PluginContext
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.knowledge.ServiceIndex
import software.amazon.smithy.model.neighbor.Walker
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeVisitor
import software.amazon.smithy.model.shapes.StringShape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.shapes.UnionShape
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.swift.codegen.integration.CustomDebugStringConvertibleGenerator
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import java.util.ServiceLoader
import java.util.logging.Logger

class CodegenVisitor(context: PluginContext) : ShapeVisitor.Default<Void>() {

    private val LOGGER = Logger.getLogger(javaClass.name)
    private val settings: SwiftSettings = SwiftSettings.from(context.model, context.settings)
    private val model: Model
    private val service: ServiceShape
    private val fileManifest: FileManifest = context.fileManifest
    private val symbolProvider: SymbolProvider
    private val writers: SwiftDelegator
    private val integrations: List<SwiftIntegration>
    private val protocolGenerator: ProtocolGenerator?

    init {
        LOGGER.info("Attempting to discover SwiftIntegration from classpath...")
        integrations = ServiceLoader.load(SwiftIntegration::class.java, context.pluginClassLoader.orElse(javaClass.classLoader))
            .also { integration ->
                LOGGER.info("Adding SwiftIntegration: ${integration.javaClass.name}")
            }.sortedBy(SwiftIntegration::order).toList()

        LOGGER.info("Preprocessing model")
        var resolvedModel = context.model
        for (integration in integrations) {
            resolvedModel = integration.preprocessModel(resolvedModel, settings)
        }
        // Add operation input/output shapes if not provided for future evolution of sdk
        resolvedModel = AddOperationShapes.execute(resolvedModel, settings.getService(resolvedModel), settings.moduleName)
        resolvedModel = RecursiveShapeBoxer.transform(resolvedModel)
        model = resolvedModel

        service = settings.getService(model)

        var resolvedSymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, settings)
        for (integration in integrations) {
            resolvedSymbolProvider = integration.decorateSymbolProvider(settings, model, resolvedSymbolProvider)
        }
        symbolProvider = resolvedSymbolProvider

        writers = SwiftDelegator(settings, model, fileManifest, symbolProvider, integrations)
        protocolGenerator = resolveProtocolGenerator(integrations, model, service, settings)
    }

    private fun resolveProtocolGenerator(
        integrations: List<SwiftIntegration>,
        model: Model,
        service: ServiceShape,
        settings: SwiftSettings
    ): ProtocolGenerator? {
        val generators = integrations.flatMap { it.protocolGenerators }.associateBy { it.protocol }
        val serviceIndex = ServiceIndex.of(model)

        try {
            val protocolTrait = settings.resolveServiceProtocol(serviceIndex, service, generators.keys)
            return generators[protocolTrait]
        } catch (ex: UnresolvableProtocolException) {
            LOGGER.warning("Unable to find protocol generator for ${service.id}: ${ex.message}")
        }
        return null
    }

    fun execute() {
        LOGGER.info("Generating Swift client for service ${settings.service}")

        println("Walking shapes from " + service.id + " to find shapes to generate")
        val serviceShapes: Set<Shape> = Walker(model).walkShapes(service)
        serviceShapes.forEach { it.accept(this) }
        var generateTestTarget = false
        protocolGenerator?.apply {
            val ctx = ProtocolGenerator.GenerationContext(
                settings,
                model,
                service,
                symbolProvider,
                integrations,
                protocolGenerator.protocol,
                writers
            )
            LOGGER.info("[${service.id}] Generating serde for protocol ${protocolGenerator.protocol}")
            generateSerializers(ctx)
            generateDeserializers(ctx)
            generateCodableConformanceForNestedTypes(ctx)

            LOGGER.info("[${service.id}] Generating unit tests for protocol ${protocolGenerator.protocol}")
            generateProtocolUnitTests(ctx)

            generateTestTarget = ctx.settings.shouldGenerateUnitTestTarget

            LOGGER.info("[${service.id}] Generating service client for protocol ${protocolGenerator.protocol}")
            generateProtocolClient(ctx)
        }

        println("Flushing swift writers")
        val dependencies = writers.dependencies
        writers.flushWriters()

        println("Generating package manifest file")
        writePackageManifest(settings, fileManifest, dependencies, generateTestTarget)
    }

    override fun getDefault(shape: Shape?): Void? {
        return null
    }

    override fun structureShape(shape: StructureShape): Void? {
        writers.useShapeWriter(shape) { writer: SwiftWriter -> StructureGenerator(model, symbolProvider, writer, shape).render() }
        writers.useShapeExtensionWriter(shape, "CustomDebugStringConvertible") { writer: SwiftWriter ->
            CustomDebugStringConvertibleGenerator(symbolProvider, writer, shape).render()
        }
        return null
    }

    override fun stringShape(shape: StringShape): Void? {
        if (shape.hasTrait(EnumTrait::class.java)) {
            writers.useShapeWriter(shape) { writer: SwiftWriter -> EnumGenerator(symbolProvider.toSymbol(shape), writer, shape).render() }
        }
        return null
    }

    override fun unionShape(shape: UnionShape): Void? {
        writers.useShapeWriter(shape) { writer: SwiftWriter -> UnionGenerator(model, symbolProvider, writer, shape).render() }
        return null
    }

    override fun serviceShape(shape: ServiceShape): Void? {
        writers.useShapeWriter(shape) {
            writer: SwiftWriter ->
            ServiceGenerator(settings, model, symbolProvider, writer, writers, protocolGenerator).render()
        }
        return null
    }
}

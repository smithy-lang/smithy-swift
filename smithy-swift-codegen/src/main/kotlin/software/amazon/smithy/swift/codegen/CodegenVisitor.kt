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
import software.amazon.smithy.model.shapes.IntegerShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeVisitor
import software.amazon.smithy.model.shapes.StringShape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.shapes.UnionShape
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.model.traits.SensitiveTrait
import software.amazon.smithy.model.transform.ModelTransformer
import software.amazon.smithy.swift.codegen.core.GenerationContext
import software.amazon.smithy.swift.codegen.integration.CustomDebugStringConvertibleGenerator
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.model.AddOperationShapes
import software.amazon.smithy.swift.codegen.model.NestedShapeTransformer
import software.amazon.smithy.swift.codegen.model.RecursiveShapeBoxer
import software.amazon.smithy.swift.codegen.model.UnionIndirectivizer
import software.amazon.smithy.swift.codegen.model.hasTrait
import java.util.ServiceLoader
import java.util.logging.Logger

class CodegenVisitor(context: PluginContext) : ShapeVisitor.Default<Void>() {

    private val LOGGER = Logger.getLogger(javaClass.name)
    private val settings: SwiftSettings = SwiftSettings.from(context.model, context.settings)
    val model: Model
    private val service: ServiceShape
    private val fileManifest: FileManifest = context.fileManifest
    private val symbolProvider: SymbolProvider
    private val writers: SwiftDelegator
    private val integrations: List<SwiftIntegration>
    private val protocolGenerator: ProtocolGenerator?
    private val baseGenerationContext: GenerationContext
    private val protocolContext: ProtocolGenerator.GenerationContext?

    init {
        LOGGER.info("Attempting to discover SwiftIntegration from classpath...")
        integrations = ServiceLoader.load(SwiftIntegration::class.java, context.pluginClassLoader.orElse(javaClass.classLoader))
            .also { integration -> LOGGER.info("Loaded SwiftIntegration: ${integration.javaClass.name}") }
            .filter { integration -> integration.enabledForService(context.model, settings) }
            .also { integration -> LOGGER.info("Enabled SwiftIntegration: ${integration.javaClass.name}") }
            .sortedBy(SwiftIntegration::order)
            .toList()

        LOGGER.info("Preprocessing model")
        var resolvedModel = context.model
        for (integration in integrations) {
            resolvedModel = integration.preprocessModel(resolvedModel, settings)
        }
        model = preprocessModel(resolvedModel)

        service = settings.getService(model)

        var resolvedSymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, settings)
        for (integration in integrations) {
            resolvedSymbolProvider = integration.decorateSymbolProvider(settings, model, resolvedSymbolProvider)
        }
        symbolProvider = resolvedSymbolProvider

        writers = SwiftDelegator(settings, model, fileManifest, symbolProvider, integrations)
        protocolGenerator = resolveProtocolGenerator(integrations, model, service, settings)

        for (integration in integrations) {
            integration.serviceErrorProtocolSymbol()?.let {
                protocolGenerator?.serviceErrorProtocolSymbol = it
            }
        }

        baseGenerationContext = GenerationContext(model, symbolProvider, settings, protocolGenerator, integrations)

        protocolContext = protocolGenerator?.let { ProtocolGenerator.GenerationContext(settings, model, service, symbolProvider, integrations, it.protocol, writers) }
    }

    fun preprocessModel(model: Model): Model {
        var resolvedModel = model
        resolvedModel = ModelTransformer.create().flattenAndRemoveMixins(resolvedModel)
        resolvedModel = AddOperationShapes.execute(resolvedModel, settings.getService(resolvedModel), settings.moduleName)
        resolvedModel = RecursiveShapeBoxer.transform(resolvedModel)
        resolvedModel = NestedShapeTransformer.transform(resolvedModel, settings.getService(resolvedModel))
        resolvedModel = UnionIndirectivizer.transform(resolvedModel)
        return resolvedModel
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
        var shouldGenerateTestTarget = false
        protocolGenerator?.apply {
            protocolContext?.let { ctx ->
                LOGGER.info("[${service.id}] Generating serde for protocol ${protocolGenerator.protocol}")
                generateSerializers(ctx)
                generateDeserializers(ctx)
                generateMessageMarshallable(ctx)
                generateMessageUnmarshallable(ctx)
                generateCodableConformanceForNestedTypes(ctx)

                initializeMiddleware(ctx)

                LOGGER.info("[${service.id}] Generating unit tests for protocol ${protocolGenerator.protocol}")
                val numProtocolUnitTestsGenerated = generateProtocolUnitTests(ctx)
                shouldGenerateTestTarget = (numProtocolUnitTestsGenerated > 0)

                LOGGER.info("[${service.id}] Generating service client for protocol ${protocolGenerator.protocol}")

                generateProtocolClient(ctx)

                integrations.forEach { it.writeAdditionalFiles(baseGenerationContext, ctx, writers) }
            }
        }

        println("Flushing swift writers")
        val dependencies = writers.dependencies
        writers.flushWriters()

        println("Generating package manifest file")
        writePackageManifest(settings, fileManifest, dependencies, shouldGenerateTestTarget)
    }

    override fun getDefault(shape: Shape?): Void? {
        return null
    }

    override fun structureShape(shape: StructureShape): Void? {
        writers.useShapeWriter(shape) { writer: SwiftWriter -> StructureGenerator(model, symbolProvider, writer, shape, settings, protocolGenerator?.serviceErrorProtocolSymbol).render() }
        if (shape.hasTrait<SensitiveTrait>() || shape.members().any { it.hasTrait<SensitiveTrait>() || model.expectShape(it.target).hasTrait<SensitiveTrait>() }) {
            writers.useShapeExtensionWriter(shape, "CustomDebugStringConvertible") { writer: SwiftWriter ->
                CustomDebugStringConvertibleGenerator(symbolProvider, writer, shape, model).render()
            }
        }
        return null
    }

    override fun stringShape(shape: StringShape): Void? {
        if (shape.hasTrait<EnumTrait>()) {
            writers.useShapeWriter(shape) { writer: SwiftWriter -> EnumGenerator(model, symbolProvider, writer, shape, settings).render() }
        }
        return null
    }

    override fun integerShape(shape: IntegerShape): Void? {
        if (shape.isIntEnumShape()) {
            writers.useShapeWriter(shape) { writer: SwiftWriter -> IntEnumGenerator(model, symbolProvider, writer, shape.asIntEnumShape().get(), settings).render() }
        }
        return null
    }

    override fun unionShape(shape: UnionShape): Void? {
        writers.useShapeWriter(shape) { writer: SwiftWriter -> UnionGenerator(model, symbolProvider, writer, shape, settings).render() }
        return null
    }

    override fun serviceShape(shape: ServiceShape): Void? {
        // This used to generate the client protocol.  No longer used.
        return null
    }
}

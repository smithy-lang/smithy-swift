/*
 * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

package software.amazon.smithy.kotlin.codegen

import java.util.*
import java.util.logging.Logger
import software.amazon.smithy.build.FileManifest
import software.amazon.smithy.build.PluginContext
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.kotlin.codegen.integration.KotlinIntegration
import software.amazon.smithy.model.neighbor.Walker
import software.amazon.smithy.model.shapes.*
import software.amazon.smithy.model.traits.EnumTrait

/**
 * Orchestrates Kotlin code generation
 */
class CodegenVisitor(context: PluginContext) : ShapeVisitor.Default<Void>() {

    val LOGGER = Logger.getLogger(javaClass.name)
    private val model = context.model
    private val modelWithoutTraits = context.modelWithoutTraitShapes
    private val settings = KotlinSettings.from(context.model, context.settings)
    private val service: ServiceShape = settings.getService(model)
    private val fileManifest: FileManifest = context.fileManifest
    private val symbolProvider: SymbolProvider = KotlinCodegenPlugin.createSymbolProvider(model, settings.moduleName)
    private val writers: KotlinDelegator = KotlinDelegator(settings, model, fileManifest, symbolProvider)
    private val integrations: List<KotlinIntegration>

    init {
        val loader = context.pluginClassLoader.orElse(javaClass.classLoader)
        LOGGER.info("Attempting to discover KotlinIntegration from classpath...")
        val loaded = mutableListOf<KotlinIntegration>()
        ServiceLoader.load(KotlinIntegration::class.java, loader)
            .forEach { integration ->
                LOGGER.info("Adding KotlinIntegration: ${integration.javaClass.name}")
                loaded.add(integration)
            }

        integrations = loaded
    }

    fun execute() {
        LOGGER.info("Generating Kotlin client for service ${settings.service}")

        LOGGER.info("Walking shapes from ${settings.service} to find shapes to generate")
        val serviceShapes = Walker(modelWithoutTraits).walkShapes(service)
        serviceShapes.forEach { it.accept(this) }

        val dependencies = writers.dependencies.map { it.properties["dependency"] as KotlinDependency }.distinct()
        writeGradleBuild(settings, fileManifest, dependencies)

        println("flushing writers")
        writers.flushWriters()
    }

    override fun getDefault(shape: Shape?): Void? {
        return null
    }

    override fun structureShape(shape: StructureShape): Void? {
        writers.useShapeWriter(shape) { StructureGenerator(model, symbolProvider, it, shape).render() }
        return null
    }

    override fun stringShape(shape: StringShape): Void? {
        if (shape.hasTrait(EnumTrait::class.java)) {
            writers.useShapeWriter(shape) { EnumGenerator(shape, symbolProvider.toSymbol(shape), it).render() }
        }
        return null
    }

    override fun unionShape(shape: UnionShape): Void? {
        writers.useShapeWriter(shape) { UnionGenerator(model, symbolProvider, it, shape).render() }
        return null
    }

    override fun serviceShape(shape: ServiceShape): Void? {
        if (service != shape) {
            LOGGER.fine("Skipping `${shape.id}` because it is not `${service.id}`")
            return null
        }

        writers.useShapeWriter(shape) {
            ServiceGenerator(model, symbolProvider, it, shape, settings.moduleName).render()
        }
        return null
    }
}

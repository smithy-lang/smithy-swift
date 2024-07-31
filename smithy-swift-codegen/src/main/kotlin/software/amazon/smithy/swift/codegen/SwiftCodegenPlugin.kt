/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.build.PluginContext
import software.amazon.smithy.build.SmithyBuildPlugin
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.codegen.core.directed.CodegenDirector
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.transform.ModelTransformer
import software.amazon.smithy.swift.codegen.core.GenerationContext
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.model.AddOperationShapes
import software.amazon.smithy.swift.codegen.model.EquatableConformanceTransformer
import software.amazon.smithy.swift.codegen.model.NeedsReaderWriterTransformer
import software.amazon.smithy.swift.codegen.model.NestedShapeTransformer
import software.amazon.smithy.swift.codegen.model.RecursiveShapeBoxer
import software.amazon.smithy.swift.codegen.model.TestEquatableConformanceTransformer
import software.amazon.smithy.swift.codegen.model.UnionIndirectivizer
import java.util.ServiceLoader
import java.util.logging.Logger

/**
 * Plugin to trigger Swift code generation.
 */
class SwiftCodegenPlugin : SmithyBuildPlugin {

    private var resolvedModel: Model? = null

    companion object {

        private val LOGGER = Logger.getLogger(SwiftCodegenPlugin::class.java.getName())

        /**
         * Creates a Kotlin symbol provider.
         * @param model The model to generate symbols for
         * @param rootPackageNamespace The root package name (e.g. com.foo.bar). All symbols will be generated as part of this
         * package (or as a child of it)
         * @param sdkId name to use to represent client type. e.g. an sdkId of "foo" would produce a client type "FooClient".
         * @return Returns the created provider
         */
        fun createSymbolProvider(model: Model, swiftSettings: SwiftSettings): SymbolProvider = SwiftSymbolProvider(model, swiftSettings)

        fun preprocessModel(model: Model, settings: SwiftSettings, integrations: List<SwiftIntegration>): Model {
            var resolvedModel = model

            for (integration in integrations) {
                resolvedModel = integration.preprocessModel(resolvedModel, settings)
            }

            resolvedModel = ModelTransformer.create().flattenAndRemoveMixins(resolvedModel)
            resolvedModel = AddOperationShapes.execute(resolvedModel, settings.getService(resolvedModel), settings.moduleName)
            resolvedModel = RecursiveShapeBoxer.transform(resolvedModel)
            resolvedModel = NestedShapeTransformer.transform(resolvedModel, settings.getService(resolvedModel))
            resolvedModel = UnionIndirectivizer.transform(resolvedModel)
            resolvedModel = EquatableConformanceTransformer.transform(resolvedModel, settings.getService(resolvedModel))
            resolvedModel = TestEquatableConformanceTransformer.transform(resolvedModel, settings.getService(resolvedModel))
            resolvedModel = NeedsReaderWriterTransformer.transform(resolvedModel, settings.getService(resolvedModel))
            return resolvedModel
        }

        fun getEnabledIntegrations(model: Model, settings: SwiftSettings): List<SwiftIntegration> {
            return ServiceLoader.load(SwiftIntegration::class.java, CodegenDirector::class.java.getClassLoader())
                .also { integration -> LOGGER.info("Loaded SwiftIntegration: ${integration.javaClass.name}") }
                .filter { integration -> integration.enabledForService(model, settings) }
                .also { integration -> LOGGER.info("Enabled SwiftIntegration: ${integration.javaClass.name}") }
                .sortedBy(SwiftIntegration::order)
                .toList()
        }
    }

    override fun getName(): String = "swift-codegen"

    override fun execute(context: PluginContext) {
        println("executing swift codegen")

        val codegenDirector = CodegenDirector<SwiftWriter, SwiftIntegration, GenerationContext, SwiftSettings>()

        val swiftSettings = SwiftSettings.from(context.model, context.settings)

        codegenDirector.directedCodegen(DirectedSwiftCodegen(context))

        codegenDirector.settings(swiftSettings)

        codegenDirector.integrationClass(SwiftIntegration::class.java)

        codegenDirector.fileManifest(context.fileManifest)

        val enabledIntegrations = getEnabledIntegrations(context.model, swiftSettings)

        val resolvedModel = preprocessModel(context.model, swiftSettings, enabledIntegrations)

        codegenDirector.model(resolvedModel)

        codegenDirector.integrationFinder { enabledIntegrations.asIterable() }

        codegenDirector.service(swiftSettings.getService(resolvedModel).id)

        codegenDirector.run()

        this.resolvedModel = resolvedModel
    }

    fun getResolvedModel(): Model? {
        return resolvedModel
    }
}

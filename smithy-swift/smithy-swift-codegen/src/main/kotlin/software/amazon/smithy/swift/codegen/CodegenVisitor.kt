package software.amazon.smithy.swift.codegen

import software.amazon.smithy.build.FileManifest
import software.amazon.smithy.build.PluginContext
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.neighbor.Walker
import software.amazon.smithy.model.shapes.*

class CodegenVisitor(context: PluginContext) : ShapeVisitor.Default<Void>() {

    private var settings: SwiftSettings = SwiftSettings.from(context.model, context.settings)
    private var model: Model = context.model
    private var modelWithoutTraitShapes: Model = context.modelWithoutTraitShapes
    private var service: ServiceShape = settings.getService(model)
    private var fileManifest: FileManifest = context.fileManifest
    private var symbolProvider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, settings.moduleName)
    private var writers: SwiftDelegator = SwiftDelegator(settings, model, fileManifest, symbolProvider)

    fun execute() { // Generate models that are connected to the service being generated.
        println("Walking shapes from " + service.id + " to find shapes to generate")
        val serviceShapes: Set<Shape> = Walker(modelWithoutTraitShapes).walkShapes(service)
        for (shape in serviceShapes) {
            shape.accept(this)
        }

        println("Flushing swift writers")

        writers.flushWriters()

        println("Generating swift podspec file")
        // TODO: Generate podspec file
        // val dependencies = this.writers.dependencies
        // PodSpecGenerator.writePodspec(settings, fileManifest, SymbolDependency.gatherDependencies(dependencies.stream()))
    }

    override fun getDefault(shape: Shape?): Void? {
        return null
    }

    override fun structureShape(shape: StructureShape): Void? {
        writers.useShapeWriter(shape) { writer: SwiftWriter -> StructureGenerator(model, symbolProvider, writer, shape).render() }
        return null
    }

    override fun unionShape(shape: UnionShape): Void? {
        writers.useShapeWriter(
            shape
        ) { writer: SwiftWriter? -> EnumGenerator(symbolProvider, writer, shape).render() }
        return null
    }

    override fun serviceShape(shape: ServiceShape?): Void? {
        // TODO: implement client generation
        writers.useShapeWriter(shape) { writer: SwiftWriter? -> }
        return null
    }
}

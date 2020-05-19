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

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.build.FileManifest
import software.amazon.smithy.build.PluginContext
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.neighbor.Walker
import software.amazon.smithy.model.shapes.*
import software.amazon.smithy.model.traits.EnumTrait

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
        val dependencies = writers.dependencies
        writers.flushWriters()

        println("Generating swift podspec file")
        writePodspec(settings, fileManifest, dependencies)

        println("Generating info plist")
        writeInfoPlist(settings, fileManifest)
    }

    override fun getDefault(shape: Shape?): Void? {
        return null
    }

    override fun structureShape(shape: StructureShape): Void? {
        writers.useShapeWriter(shape) { writer: SwiftWriter -> StructureGenerator(model, symbolProvider, writer, shape, service.defaultName()).render() }
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

    override fun serviceShape(shape: ServiceShape?): Void? {
        // TODO: implement client generation
        writers.useShapeWriter(shape) {
            // TODO:: Generate Service Client
        }
        return null
    }
}

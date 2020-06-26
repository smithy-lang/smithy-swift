/*
 *
 *  * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  *
 *  * Licensed under the Apache License, Version 2.0 (the "License").
 *  * You may not use this file except in compliance with the License.
 *  * A copy of the License is located at
 *  *
 *  *  http://aws.amazon.com/apache2.0
 *  *
 *  * or in the "license" file accompanying this file. This file is distributed
 *  * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 *  * express or implied. See the License for the specific language governing
 *  * permissions and limitations under the License.
 *
 */

package software.amazon.smithy.swift.codegen.integration

import java.awt.Shape
import software.amazon.smithy.build.PluginContext
import software.amazon.smithy.codegen.core.SymbolDependency
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.codegen.core.SymbolReference
import software.amazon.smithy.model.Model
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.SwiftWriter

/**
 * Kotlin SPI for customizing Swift code generation, registering
 * new protocol code generators, renaming shapes, modifying the model,
 * adding custom code, etc.
 */
interface SwiftIntegration {
    /**
     * Gets the sort order of the customization from -128 to 127.
     *
     *
     * Customizations are applied according to this sort order. Lower values
     * are executed before higher values (for example, -128 comes before 0,
     * comes before 127). Customizations default to 0, which is the middle point
     * between the minimum and maximum order values. The customization
     * applied later can override the runtime configurations that provided
     * by customizations applied earlier.
     *
     * @return Returns the sort order, defaulting to 0.
     */
    fun getOrder(): Byte {
        return 0
    }

    /**
     * Preprocess the model before code generation.
     *
     *
     * This can be used to remove unsupported features, remove traits
     * from shapes (e.g., make members optional), etc.
     *
     * @param context Plugin context.
     * @param settings Setting used to generate.
     * @return Returns the updated model.
     */
    fun preprocessModel(context: PluginContext, settings: SwiftSettings): Model? {
        return context.model
    }

    /**
     * Updates the [SymbolProvider] used when generating code.
     *
     *
     * This can be used to customize the names of shapes, the package
     * that code is generated into, add dependencies, add imports, etc.
     *
     * @param settings Setting used to generate.
     * @param model Model being generated.
     * @param symbolProvider The original `SymbolProvider`.
     * @return The decorated `SymbolProvider`.
     */
    fun decorateSymbolProvider(
        settings: SwiftSettings,
        model: Model,
        symbolProvider: SymbolProvider
    ): SymbolProvider {
        return symbolProvider
    }

    /**
     * Called each time a writer is used that defines a shape.
     *
     *
     * This method could be called multiple times for the same writer
     * but for different shapes. It gives an opportunity to intercept code
     * sections of a [SwiftWriter] by name using the shape for
     * context. For example:
     *
     * <pre>
     * `public class MyIntegration: SwiftIntegration {
     * fun onWriterUse(settings: SwiftSettings, model:Model, symbolProvider:SymbolProvider,
     * writer: SwiftWriter, definedShape: Shape) {
     * writer.onSection("example", text -&gt; writer.write("Intercepted: " + text"));
     * }
     * }
    `</pre> *
     *
     *
     * Any mutations made on the writer (for example, adding
     * section interceptors) are removed after the callback has completed;
     * the callback is invoked in between pushing and popping state from
     * the writer.
     *
     * @param settings Settings used to generate.
     * @param model Model to generate from.
     * @param symbolProvider Symbol provider used for codegen.
     * @param writer Writer that will be used.
     * @param definedShape Shape that is being defined in the writer.
     */
    fun onShapeWriterUse(
        settings: SwiftSettings,
        model: Model,
        symbolProvider: SymbolProvider,
        writer: SwiftWriter,
        definedShape: Shape
    )

    /**
     * Writes additional files.
     *
     * <pre>
     * `public class MyIntegration: SwiftIntegration {
     * fun writeAdditionalFiles(
     * settings: SwiftSettings,
     * model: Model,
     * symbolProvider: SymbolProvider,
     * writerFactory: (String, (SwiftWriter) -> Unit) -> Unit
     * ) {
     * writerFactory("foo.swift", { it.write("// Hello!")})
     * }
     * }
    `</pre> *
     *
     * @param settings Settings used to generate.
     * @param model Model to generate from.
     * @param symbolProvider Symbol provider used for codegen.
     * @param writerFactory A factory function that takes the name of a file
     * to write and a closure that receives a
     * [SwiftWriter] to perform the actual writing to the file.
     */
    fun writeAdditionalFiles(
        settings: SwiftSettings,
        model: Model?,
        symbolProvider: SymbolProvider?,
        writerFactory: (String, (SwiftWriter) -> Unit) -> Unit
    )

    /**
     * Adds additional client config interface fields.
     *
     *
     * Implementations of this method are expected to add fields to the
     * "ClientDefaults" interface of a generated client. This interface
     * contains fields that are either statically generated from
     * a model or are dependent on the runtime that a client is running in.
     * Implementations are expected to write interface field names and
     * their type signatures, each followed by a semicolon (;). Any number
     * of fields can be added, and any [Symbol] or
     * [SymbolReference] objects that are written to the writer are
     * automatically imported, and any of their contained
     * [SymbolDependency] values are automatically added to the
     * generated `package.json` file.
     *
     *
     * For example, the following code adds two fields to a client:
     *
     * <pre>
     * `public final class MyIntegration implements SwiftIntegration {
     * public void addConfigInterfaceFields(
     * SwiftSettings settings,
     * Model model,
     * SymbolProvider symbolProvider,
     * SwiftWriter writer
     * ) {
     * writer.writeDocs("The docs for foo...")
     * writer.write("foo?: string;")
     *
     * writer.writeDocs("The docs for bar...")
     * writer.write("bar?: string;")
     * }
     * }
    `</pre> *
     *
     * @param settings Settings used to generate.
     * @param model Model to generate from.
     * @param symbolProvider Symbol provider used for codegen.
     * @param writer TypeScript writer to write to.
     */
    fun addConfigInterfaceFields(
        settings: SwiftSettings,
        model: Model,
        symbolProvider: SymbolProvider,
        writer: SwiftWriter
    )
}

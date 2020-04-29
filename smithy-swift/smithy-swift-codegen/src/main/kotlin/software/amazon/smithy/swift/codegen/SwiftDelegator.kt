package software.amazon.smithy.swift.codegen

import software.amazon.smithy.build.FileManifest
import software.amazon.smithy.codegen.core.SymbolDependency
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.codegen.core.SymbolReference
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.Shape
import java.nio.file.Paths


/**
 * Manages writers for Swift files.
 */
class SwiftDelegator(private val settings: SwiftSettings,
                      private val model: Model,
                      private val fileManifest: FileManifest,
                      private val symbolProvider: SymbolProvider){

    private val writers: MutableMap<String, SwiftWriter> = mutableMapOf()


    /**
     * Writes all pending writers to disk and then clears them out.
     */
    fun flushWriters() {
        writers.forEach() { (filename, writer) ->
            fileManifest.writeFile(filename, writer.toString())
        }
        writers.clear()
    }

    /**
     * Gets all of the dependencies that have been registered in writers owned by the delegator.
     *
     * @return Returns all the dependencies.
     */
    val dependencies: List<SymbolDependency>
        get() {
            return writers.values.flatMap(SwiftWriter::dependencies)
        }

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
        val writer: SwiftWriter = checkoutWriter(symbol.definitionFile)

        // Add any needed DECLARE symbols.
        writer.addImportReferences(symbol, SymbolReference.ContextOption.DECLARE)
        writer.dependencies.addAll(symbol.dependencies)
        writer.pushState()
        writerConsumer(writer)
        writer.popState()
    }

    private fun checkoutWriter(filename: String): SwiftWriter {
        val formattedFilename = Paths.get(filename).normalize().toString()
        val needsNewline = writers.containsKey(formattedFilename)
        val writer = writers.getOrPut(formattedFilename) { SwiftWriter(fullPackageName = "swift-codegen") }

        if (needsNewline) {
            writer.write("\n")
        }
        return writer
    }

}
package software.amazon.smithy.swift.codegen

import software.amazon.smithy.build.FileManifest
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.node.Node
import software.amazon.smithy.model.shapes.ModelSerializer
import software.amazon.smithy.swift.codegen.utils.SDKFileUtils

class ModelWriter {
    fun write(
        model: Model,
        manifest: FileManifest,
        settings: SwiftSettings,
    ) {
        // Convert the Model to a Node, then to pretty-printed JSON,
        // then write the JSON into the manifest
        val defaultPath = SDKFileUtils(settings).sourcesDirFilePath("model", "json")
        val astModel = ModelSerializer.builder().build().serialize(model)
        val json = Node.prettyPrintJson(astModel)
        manifest.writeFile(defaultPath, json)
    }
}

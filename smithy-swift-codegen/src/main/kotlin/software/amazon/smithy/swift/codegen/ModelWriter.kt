package software.amazon.smithy.swift.codegen

import software.amazon.smithy.build.FileManifest
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.node.Node
import software.amazon.smithy.model.shapes.ModelSerializer

class ModelWriter {
    fun write(
        model: Model,
        manifest: FileManifest,
        settings: SwiftSettings,
    ) {
        // If a model path was added to SwiftSettings, skip writing the model
        if (settings.modelPath != null) return

        // Convert the Model to a Node, then to pretty-printed JSON,
        // then write the JSON into the manifest
        val defaultPath = "Sources/${settings.moduleName}/model.json"
        val astModel = ModelSerializer.builder().build().serialize(model)
        val json = Node.prettyPrintJson(astModel)
        manifest.writeFile(defaultPath, json)
    }
}

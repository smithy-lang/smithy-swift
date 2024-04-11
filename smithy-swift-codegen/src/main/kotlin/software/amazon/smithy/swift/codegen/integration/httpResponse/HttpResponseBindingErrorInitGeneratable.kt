package software.amazon.smithy.swift.codegen.integration.httpResponse

import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

interface HttpResponseBindingErrorInitGeneratable {
    fun render(
        ctx: ProtocolGenerator.GenerationContext,
        structureShape: StructureShape,
        httpBindingResolver: HttpBindingResolver
    )
}

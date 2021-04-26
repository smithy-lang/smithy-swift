package software.amazon.smithy.swift.codegen.integration.httpResponse

import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

interface HttpResponseGenerator {
    fun render(ctx: ProtocolGenerator.GenerationContext, httpOperations: List<OperationShape>, httpBindingResolver: HttpBindingResolver)
}

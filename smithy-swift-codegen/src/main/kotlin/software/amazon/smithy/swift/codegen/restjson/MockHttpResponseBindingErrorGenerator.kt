package software.amazon.smithy.swift.codegen.restjson

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.httpResponse.HttpResponseBindingErrorGeneratable
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils

class MockHttpResponseBindingErrorGenerator : HttpResponseBindingErrorGeneratable {
    override fun render(
        ctx: ProtocolGenerator.GenerationContext,
        op: OperationShape
    ) {
        val operationErrorName = MiddlewareShapeUtils.outputErrorSymbolName(op)
        val rootNamespace = ctx.settings.moduleName
        val httpBindingSymbol = Symbol.builder()
            .definitionFile("./$rootNamespace/models/$operationErrorName+HttpResponseBinding.swift")
            .name(operationErrorName)
            .build()

        ctx.delegator.useShapeWriter(httpBindingSymbol) { writer ->
            writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
            writer.openBlock("extension \$L: \$N {", "}", operationErrorName, ClientRuntimeTypes.Http.HttpResponseBinding) {
                writer.openBlock("public init(httpResponse: \$N, decoder: \$D) throws {", "}", ClientRuntimeTypes.Http.HttpResponse, ClientRuntimeTypes.Serde.ResponseDecoder) {
                    writer.write("throw ClientError.deserializationFailed(ClientError.dataNotFound(\"Invalid information in current codegen context to resolve the ErrorType\"))")
                }
            }
        }
    }
}
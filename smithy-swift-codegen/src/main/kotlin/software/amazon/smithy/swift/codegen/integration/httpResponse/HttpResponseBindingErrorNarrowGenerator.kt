package software.amazon.smithy.swift.codegen.integration.httpResponse

import software.amazon.smithy.aws.traits.protocols.AwsQueryErrorTrait
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.swift.codegen.ServiceGenerator
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.model.getTrait

class HttpResponseBindingErrorNarrowGenerator(
    val ctx: ProtocolGenerator.GenerationContext,
    val op: OperationShape,
    val unknownServiceErrorSymbol: Symbol
) {

    fun render() {
        val errorShapes = op.errors.map { ctx.model.expectShape(it) as StructureShape }.toSet().sorted()
        val operationErrorName = ServiceGenerator.getOperationErrorShapeName(op)
        val rootNamespace = ctx.settings.moduleName
        val httpBindingSymbol = Symbol.builder()
            .definitionFile("./$rootNamespace/models/$operationErrorName+HttpResponseBinding.swift")
            .name(operationErrorName)
            .build()

        ctx.delegator.useShapeWriter(httpBindingSymbol) { writer ->
            writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
            writer.addImport(unknownServiceErrorSymbol)
            val unknownServiceErrorType = unknownServiceErrorSymbol.name

            writer.openBlock("extension \$L {", "}", operationErrorName) {
                writer.openBlock("public init(errorType: String?, httpResponse: HttpResponse, decoder: ResponseDecoder? = nil, message: String? = nil, requestID: String? = nil) throws {", "}") {
                    writer.write("switch errorType {")
                    for (errorShape in errorShapes) {
                        var errorShapeName = resolveErrorShapeName(errorShape)
                        var errorShapeType = ctx.symbolProvider.toSymbol(errorShape).name
                        var errorShapeEnumCase = errorShapeType.decapitalize()
                        writer.write("case \$S : self = .\$L(try \$L(httpResponse: httpResponse, decoder: decoder, message: message, requestID: requestID))", errorShapeName, errorShapeEnumCase, errorShapeType)
                    }
                    writer.write("default : self = .unknown($unknownServiceErrorType(httpResponse: httpResponse, message: message, requestID: requestID))")
                    writer.write("}")
                }
            }
        }
    }

    //TODO: Move to be called from a protocol
    private fun resolveErrorShapeName(errorShape: StructureShape): String {
        errorShape.getTrait<AwsQueryErrorTrait>()?.let {
            return it.code
        } ?: run {
            return ctx.symbolProvider.toSymbol(errorShape).name
        }
    }
}

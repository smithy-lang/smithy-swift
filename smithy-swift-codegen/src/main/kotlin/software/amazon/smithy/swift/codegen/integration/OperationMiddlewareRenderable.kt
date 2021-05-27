package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.swift.codegen.SwiftWriter

/**
 * Interface that allows middleware to be registered and configured with the generated protocol client
 * How this interface is used is entirely protocol/generator dependent
 */
interface OperationMiddlewareRenderable {

    val name: String

    val middlewareStep: MiddlewareStep

    val position: MiddlewarePosition

    fun render(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, serviceShape: ServiceShape, op: OperationShape, operationStackName: String) {}

    fun middlewareParamsString(ctx: ProtocolGenerator.GenerationContext, serviceShape: ServiceShape, op: OperationShape): String { return "" }
}

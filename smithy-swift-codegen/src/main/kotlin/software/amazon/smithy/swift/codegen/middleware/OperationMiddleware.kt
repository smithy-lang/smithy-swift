package software.amazon.smithy.swift.codegen.middleware

import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.MiddlewareStep
import software.amazon.smithy.swift.codegen.integration.OperationMiddlewareRenderable
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.utils.CodeWriter

//enum class MiddlewareStep {
//    INITIALIZE,
//    SERIALIZE,
//    BUILD,
//    FINALIZE,
//    DESERIALIZE
//}

typealias RenderMiddlewareCallback = (CodeWriter, OperationMiddlewareRenderable) -> Boolean

fun defaultToTrue(codeWriter: CodeWriter, operationMiddlewareRenderable: OperationMiddlewareRenderable): Boolean {
    return true
}

interface OperationMiddleware {
    fun appendMiddleware(operation: OperationShape, step: MiddlewareStep, renderableMiddleware: OperationMiddlewareRenderable)
    fun prependMiddleware(operation: OperationShape, step: MiddlewareStep, renderableMiddleware: OperationMiddlewareRenderable)
    fun removeMiddleware(operation: OperationShape, step: MiddlewareStep, middlewareName: String)

    fun renderMiddleware(ctx: ProtocolGenerator.GenerationContext,
                         writer: SwiftWriter,
                         serviceShape: ServiceShape,
                         operation: OperationShape,
                         operationStackName: String,
                         step: MiddlewareStep,
                         callback: RenderMiddlewareCallback = ::defaultToTrue)
}


package software.amazon.smithy.swift.codegen.integration.middlewares

import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.middleware.MiddlewarePosition
import software.amazon.smithy.swift.codegen.middleware.MiddlewareStep
import software.amazon.smithy.swift.codegen.model.capitalizedName

class ContentMD5Middleware {
    val name = "ContentMD5Middleware"

    val middlewareStep = MiddlewareStep.BUILDSTEP

    val position = MiddlewarePosition.BEFORE

    fun render(
        op: OperationShape,
        writer: SwiftWriter,
        outputShapeName: String,
        operationStackName: String
    ) {
        val outputErrorName = "${op.capitalizedName()}OutputError"
        writer.write("$operationStackName.${middlewareStep.stringValue()}.intercept(position: ${position.stringValue()}, middleware: \$N<$outputShapeName, $outputErrorName>())", ClientRuntimeTypes.Middleware.ContentMD5Middleware)
    }
}

package software.amazon.smithy.swift.codegen.middleware

import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

interface OperationMiddlewareFactory {
    fun createOperationMiddleware(ctx: ProtocolGenerator.GenerationContext, httpBindingResolver: HttpBindingResolver): OperationMiddleware
}
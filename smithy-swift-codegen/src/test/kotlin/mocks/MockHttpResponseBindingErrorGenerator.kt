/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package mocks

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.httpResponse.HttpResponseBindingErrorGeneratable
import software.amazon.smithy.swift.codegen.integration.middlewares.handlers.MiddlewareShapeUtils

class MockHttpResponseBindingErrorGenerator : HttpResponseBindingErrorGeneratable {
    override fun renderOperationError(
        ctx: ProtocolGenerator.GenerationContext,
        op: OperationShape,
        unknownServiceErrorSymbol: Symbol
    ) {
        val operationErrorName = MiddlewareShapeUtils.outputErrorSymbolName(op)
        val rootNamespace = ctx.settings.moduleName
        val httpBindingSymbol = Symbol.builder()
            .definitionFile("./$rootNamespace/models/$operationErrorName+HttpResponseBinding.swift")
            .name(operationErrorName)
            .build()

        ctx.delegator.useShapeWriter(httpBindingSymbol) { writer ->
            writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
            writer.openBlock("extension \$L {", "}", operationErrorName) {
                writer.openBlock("public init(httpResponse: HttpResponse, decoder: ResponseDecoder? = nil, messageDecoder: MessageDecoder? = nil) throws {", "}") {
                    writer.write("throw ClientError.deserializationFailed(ClientError.dataNotFound(\"Invalid information in current codegen context to resolve the ErrorType\"))")
                }
            }
        }
    }

    override fun renderServiceError(ctx: ProtocolGenerator.GenerationContext) {
        TODO("Organize test suites of smithy-swift and aws-sdk-swift " +
                "and see if this class and consumers of this class should be moved to aws-sdk-swift " +
                "OR AWS protocol tests in aws-sdk-swift should be moved to smithy-swift.")
    }
}

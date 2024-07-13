/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.middleware

import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

/**
 * Interface that allows middleware to be registered and configured with the generated protocol client
 * How this interface is used is entirely protocol/generator dependent
 */
interface MiddlewareRenderable {
    val name: String

    /**
     * Primary render method - what actually gets called to generate the middleware.
     *
     * The default implementation calls `renderSpecific` with the method name
     * `interceptors.add`.
     *
     * @see renderSpecific
     */
    fun render(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, op: OperationShape, operationStackName: String) {
        renderSpecific(ctx, writer, op, operationStackName, "interceptors.add")
    }

    /**
     * Utility method for rendering the initializer for the middleware.
     */
    fun renderMiddlewareInit(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, op: OperationShape) {}

    /**
     * Renders a specific method call on the orchestrator. `renderMiddlewareInit` is called to generate the middleware.
     *
     * @see renderMiddlewareInit
     */
    fun renderSpecific(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape,
        operationStackName: String,
        orchestratorMethodName: String,
    ) {
        writer.write(
            "builder.\$L(\$C)",
            orchestratorMethodName,
            Runnable { renderMiddlewareInit(ctx, writer, op) }
        )
    }
}

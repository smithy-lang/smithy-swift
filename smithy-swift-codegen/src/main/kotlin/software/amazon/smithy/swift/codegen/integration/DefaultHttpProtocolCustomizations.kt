/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.aws.swift.codegen.EndpointResolverGenerator
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.swift.codegen.AuthSchemeResolverGenerator
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.endpoint.EndpointResolverMiddleware

abstract class DefaultHttpProtocolCustomizations : HttpProtocolCustomizable {
    override fun serviceClient(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        serviceConfig: ServiceConfig
    ): HttpProtocolServiceClient {
        val clientProperties = getClientProperties()
        return HttpProtocolServiceClient(ctx, writer, clientProperties, serviceConfig)
    }

    override fun renderEventStreamAttributes(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        op: OperationShape
    ) {
        // Default implementation is no-op
    }

    override fun renderInternals(ctx: ProtocolGenerator.GenerationContext) {
        AuthSchemeResolverGenerator().render(ctx)
        EndpointResolverGenerator(
            { writer, input, output, outputError -> EndpointResolverMiddleware(writer, input, output, outputError) },
            ClientRuntimeTypes.Core.PartitionDefinition
        ).render(ctx)
    }
}

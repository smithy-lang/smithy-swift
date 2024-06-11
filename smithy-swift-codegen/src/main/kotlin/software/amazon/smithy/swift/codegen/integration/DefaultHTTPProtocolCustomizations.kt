/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.AuthSchemeResolverGenerator
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.endpoints.EndpointParamsGenerator
import software.amazon.smithy.swift.codegen.endpoints.EndpointResolverGenerator
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyTestUtilTypes

abstract class DefaultHTTPProtocolCustomizations : HTTPProtocolCustomizable {
    override fun serviceClient(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        serviceConfig: ServiceConfig
    ): HttpProtocolServiceClient {
        return HttpProtocolServiceClient(ctx, writer, serviceConfig)
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
        EndpointParamsGenerator(ctx).render()
        EndpointResolverGenerator(
            partitionDefinition = ClientRuntimeTypes.Core.PartitionDefinition,
        ).render(ctx)
    }

    override val endpointMiddlewareSymbol: Symbol = ClientRuntimeTypes.Core.EndpointResolverMiddleware

    override val baseErrorSymbol: Symbol = SmithyTestUtilTypes.TestBaseError

    override val unknownServiceErrorSymbol: Symbol = ClientRuntimeTypes.Http.UnknownHttpServiceError

    override val defaultTimestampFormat = TimestampFormatTrait.Format.EPOCH_SECONDS
}

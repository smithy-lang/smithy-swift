/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.AuthSchemeResolverGenerator
import software.amazon.smithy.swift.codegen.SmithyTestUtilTypes
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.endpoints.EndpointResolverGenerator
import software.amazon.smithy.swift.codegen.middleware.EndpointResolverMiddleware
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyEventStreamsAPITypes

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
        EndpointResolverGenerator(
            partitionDefinition = ClientRuntimeTypes.Core.PartitionDefinition,
            dependency = SwiftDependency.CLIENT_RUNTIME,
            endpointResolverMiddleware = { w, i, o, oe -> EndpointResolverMiddleware(w, i, o, oe) }
        ).render(ctx)
    }

    override val messageDecoderSymbol: Symbol = SmithyEventStreamsAPITypes.MessageDecoder

    override val baseErrorSymbol: Symbol = SmithyTestUtilTypes.TestBaseError

    override val unknownServiceErrorSymbol: Symbol = ClientRuntimeTypes.Http.UnknownHttpServiceError

    override val defaultTimestampFormat = TimestampFormatTrait.Format.EPOCH_SECONDS
}

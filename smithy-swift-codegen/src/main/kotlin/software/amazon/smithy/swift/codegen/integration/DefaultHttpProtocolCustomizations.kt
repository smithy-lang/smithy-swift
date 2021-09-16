/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.swift.codegen.SwiftWriter

abstract class DefaultHttpProtocolCustomizations : HttpProtocolCustomizable {
    override fun serviceClient(
        ctx: ProtocolGenerator.GenerationContext,
        writer: SwiftWriter,
        serviceConfig: ServiceConfig
    ): HttpProtocolServiceClient {
        val clientProperties = getClientProperties()
        return HttpProtocolServiceClient(ctx, writer, clientProperties, serviceConfig)
    }
}

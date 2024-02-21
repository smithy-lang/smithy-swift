/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.swift.codegen.config.ClientConfiguration
import software.amazon.smithy.swift.codegen.config.DefaultClientConfiguration
import software.amazon.smithy.swift.codegen.config.DefaultHttpClientConfiguration
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration

class DefaultClientConfigurationIntegration : SwiftIntegration {
    override fun clientConfigurations(ctx: ProtocolGenerator.GenerationContext): List<ClientConfiguration> {
        return listOf(DefaultClientConfiguration(), DefaultHttpClientConfiguration())
    }
}

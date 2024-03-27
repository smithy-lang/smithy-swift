/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.core.GenerationContext
import software.amazon.smithy.swift.codegen.integration.HttpProtocolServiceClient.ConfigClassVariablesCustomization
import software.amazon.smithy.swift.codegen.integration.HttpProtocolServiceClient.ConfigInitializerCustomization
import software.amazon.smithy.utils.CodeInterceptor
import software.amazon.smithy.utils.CodeSection

class ExtractTelemetryLoggerConfig : SwiftIntegration {
    override fun interceptors(codegenContext: GenerationContext): List<out CodeInterceptor<out CodeSection?, SwiftWriter>?> {
        return listOf(PrivateLoggerConfigVariable(), LoggerConfigInitializer())
    }

    private class PrivateLoggerConfigVariable : CodeInterceptor.Appender<ConfigClassVariablesCustomization, SwiftWriter> {
        override fun sectionType(): Class<ConfigClassVariablesCustomization> {
            return ConfigClassVariablesCustomization::class.java
        }

        override fun append(writer: SwiftWriter, section: ConfigClassVariablesCustomization) {
            writer.write("fileprivate var logger: \$N", ClientRuntimeTypes.Core.Logger)
            writer.write("")
        }
    }

    private class LoggerConfigInitializer : CodeInterceptor.Appender<ConfigInitializerCustomization, SwiftWriter> {
        override fun sectionType(): Class<ConfigInitializerCustomization> {
            return ConfigInitializerCustomization::class.java
        }

        override fun append(writer: SwiftWriter, section: ConfigInitializerCustomization) {
            writer.write("self.logger = telemetryProvider.loggerProvider.getLogger(name: \$L.clientName)", section.serviceSymbol.name)
        }
    }
}

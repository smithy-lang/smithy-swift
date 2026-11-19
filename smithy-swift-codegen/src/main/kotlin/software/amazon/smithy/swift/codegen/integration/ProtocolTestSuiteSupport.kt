/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.model.hasEndpointRules
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyHTTPAPITypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyTestUtilTypes
import software.amazon.smithy.swift.codegen.utils.SDKFileUtils

/**
 * Opens the test file with the passed name, adds the imports that all generated protocol test suites use,
 * then calls [block] to render the suite(s) in the file.
 */
internal fun ProtocolGenerator.GenerationContext.useTestSuiteWriter(
    fileName: String,
    block: (SwiftWriter) -> Unit,
) {
    val filename = SDKFileUtils(settings).testsDirFilePath(fileName)
    delegator.useTestFileWriter(filename, settings.moduleName) { writer ->
        writer.addImport(SwiftDependency.SWIFT_TESTING.target)
        // Generated tests use Foundation types; unlike XCTest, Swift Testing does not re-export Foundation.
        writer.addImport("Foundation")
        writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
        writer.addImport(settings.moduleName, true)
        writer.addImport(SwiftDependency.SMITHY_TEST_UTIL.target)
        block(writer)
    }
}

/**
 * The kind of client that a protocol test creates.
 */
internal enum class ProtocolTestClientKind {
    /** A client whose HTTP client engine captures, rather than sends, the request. */
    REQUEST,

    /** A client whose HTTP client engine returns a passed response for every request. */
    RESPONSE,
}

/**
 * Renders a private `makeClient` helper method, for use by the tests in a protocol test suite.
 *
 * The client uses dummy credentials, and a static endpoint unless the service has endpoint rules.
 * - A [ProtocolTestClientKind.REQUEST] client is made with `makeClient(host:)`.
 * - A [ProtocolTestClientKind.RESPONSE] client is made with `makeClient(httpResponse:host:)`.
 *
 * The `host:` parameter is only present when the service has no endpoint rules, and defaults to `example.com`.
 *
 * @param telemetryProvider if true, the helper takes an optional serde benchmark telemetry provider.
 * @param eventStreams if true, the client is configured to encode & sign event stream messages for tests.
 */
internal fun ProtocolGenerator.GenerationContext.renderMakeClient(
    writer: SwiftWriter,
    kind: ProtocolTestClientKind,
    telemetryProvider: Boolean = false,
    eventStreams: Boolean = false,
) {
    val clientName = "${settings.clientBaseName}Client"
    val region = "us-west-2"
    val hasStaticEndpoint = !service.hasEndpointRules()
    val params = mutableListOf<String>()
    if (kind == ProtocolTestClientKind.RESPONSE) {
        params.add(writer.format("httpResponse: \$N", SmithyHTTPAPITypes.HTTPResponse))
    }
    if (hasStaticEndpoint) {
        params.add("host: String = \"example.com\"")
    }
    if (telemetryProvider) {
        params.add(writer.format("telemetryProvider: \$N? = nil", SmithyTestUtilTypes.SerdeBenchmarkTelemetryProvider))
    }
    writer.write("")
    writer.openBlock("private func makeClient(\$L) async throws -> \$L {", "}", params.joinToString(", "), clientName) {
        writer.openBlock("let config = try await \$1L.\$1LConfig(", ")", clientName) {
            val args = mutableListOf<String>()
            args.add(writer.format("awsCredentialIdentityResolver: try \$N()", SmithyTestUtilTypes.dummyIdentityResolver))
            args.add(writer.format("region: \$S", region))
            args.add(writer.format("signingRegion: \$S", region))
            if (hasStaticEndpoint) {
                args.add(
                    writer.format(
                        "endpointResolver: \$L.StaticEndpointResolver(endpoint: try \$N(urlString: \"https://\\(host)\"))",
                        settings.moduleName,
                        SmithyHTTPAPITypes.Endpoint,
                    ),
                )
            }
            if (telemetryProvider) {
                args.add("telemetryProvider: telemetryProvider")
            }
            when (kind) {
                ProtocolTestClientKind.REQUEST -> {
                    args.add(writer.format("idempotencyTokenGenerator: \$N()", SmithyTestUtilTypes.ProtocolTestIdempotencyTokenGenerator))
                    args.add(writer.format("httpClientEngine: \$N()", SmithyTestUtilTypes.ProtocolTestClient))
                }
                ProtocolTestClientKind.RESPONSE -> {
                    args.add(writer.format("retryStrategyOptions: \$N.make()", SmithyTestUtilTypes.ProtocolTestRetryStrategyOptions))
                    args.add(
                        writer.format("httpClientEngine: \$N(httpResponse: httpResponse)", SmithyTestUtilTypes.ProtocolResponseTestClient),
                    )
                }
            }
            if (eventStreams) {
                args.add(writer.format("httpInterceptorProviders: [\$N()]", SmithyTestUtilTypes.EventStreamTestInterceptorProvider))
            }
            writer.write(args.joinToString(",\n"))
        }
        writer.write("return \$L(config: config)", clientName)
    }
}

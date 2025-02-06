package software.amazon.smithy.swift.codegen.core

import software.amazon.smithy.build.FileManifest
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.swift.codegen.SwiftDelegator
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration

/**
 * Common codegen properties required across different codegen contexts
 */
interface SwiftCodegenContext : software.amazon.smithy.codegen.core.CodegenContext<SwiftSettings, SwiftWriter, SwiftIntegration> {
    val model: Model
    val symbolProvider: SymbolProvider
    val settings: SwiftSettings
    val fileManifest: FileManifest
    val protocolGenerator: ProtocolGenerator?
    val integrations: List<SwiftIntegration>
}

/**
 * Base generation context
 */
data class GenerationContext(
    override val model: Model,
    override val symbolProvider: SymbolProvider,
    override val settings: SwiftSettings,
    override val fileManifest: FileManifest,
    override val protocolGenerator: ProtocolGenerator? = null,
    override val integrations: List<SwiftIntegration> = listOf(),
    private val writerDelegator: SwiftDelegator = SwiftDelegator(settings, model, fileManifest, symbolProvider, integrations),
) : SwiftCodegenContext {
    override fun model(): Model = model

    override fun settings(): SwiftSettings = settings

    override fun symbolProvider(): SymbolProvider = symbolProvider

    override fun fileManifest(): FileManifest = fileManifest

    override fun writerDelegator(): SwiftDelegator = writerDelegator

    override fun integrations(): MutableList<SwiftIntegration> = integrations.toMutableList()
}

fun SwiftCodegenContext.toProtocolGenerationContext(
    serviceShape: ServiceShape,
    swiftDelegator: SwiftDelegator,
): ProtocolGenerator.GenerationContext? {
    val protocol =
        protocolGenerator?.let { it.protocol } ?: run {
            return null
        }
    return ProtocolGenerator.GenerationContext(
        settings,
        model,
        serviceShape,
        symbolProvider,
        integrations,
        protocol,
        swiftDelegator,
    )
}

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
interface CodegenContext : software.amazon.smithy.codegen.core.CodegenContext<SwiftSettings, SwiftWriter, SwiftIntegration> {
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
    private val writerDelegator: SwiftDelegator = SwiftDelegator(settings, model, fileManifest, symbolProvider, integrations)
) : CodegenContext {
    override fun model(): Model {
        return model
    }

    override fun settings(): SwiftSettings {
        return settings
    }

    override fun symbolProvider(): SymbolProvider {
        return symbolProvider
    }

    override fun fileManifest(): FileManifest {
        return fileManifest
    }

    override fun writerDelegator(): SwiftDelegator {
        return writerDelegator
    }

    override fun integrations(): MutableList<SwiftIntegration> {
        return integrations.toMutableList()
    }
}

fun CodegenContext.toProtocolGenerationContext(serviceShape: ServiceShape, swiftDelegator: SwiftDelegator): ProtocolGenerator.GenerationContext? {
    val protocol = protocolGenerator?.let { it.protocol } ?: run {
        return null
    }
    return ProtocolGenerator.GenerationContext(
        settings,
        model,
        serviceShape,
        symbolProvider,
        integrations,
        protocol,
        swiftDelegator
    )
}

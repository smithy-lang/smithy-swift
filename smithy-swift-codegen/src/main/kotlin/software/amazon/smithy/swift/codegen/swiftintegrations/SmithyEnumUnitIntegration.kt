package software.amazon.smithy.swift.codegen.swiftintegrations

import software.amazon.smithy.model.Model
import software.amazon.smithy.swift.codegen.SwiftDelegator
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.core.SwiftCodegenContext
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.SwiftIntegration
import software.amazon.smithy.swift.codegen.model.nestedNamespaceType
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyReadWriteTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SwiftTypes
import software.amazon.smithy.swift.codegen.utils.ModelFileUtils

class SmithyEnumUnitIntegration : SwiftIntegration {
    override fun enabledForService(model: Model, settings: SwiftSettings): Boolean {
        return true
    }

    override fun writeAdditionalFiles(
        ctx: SwiftCodegenContext,
        protoCtx: ProtocolGenerator.GenerationContext,
        delegator: SwiftDelegator
    ) {
        val service = ctx.settings.getService(ctx.model)
        val namespaceName = service.nestedNamespaceType(ctx.symbolProvider).name
        val structFilename = ModelFileUtils.filename(ctx.settings, "EnumUnit")
        delegator.useFileWriter(structFilename) { writer ->
            writer.openBlock("public extension \$L {", "}", namespaceName) {
                writer.write("")
                writer.openBlock(
                    "struct EnumUnit: \$N {",
                    "}",
                    SwiftTypes.Protocols.Sendable,
                ) {
                    writer.write("public init() {}")
                }
            }
        }

        val schemaFilename = ModelFileUtils.filename(ctx.settings, "EnumUnit+Schema")
        delegator.useFileWriter(schemaFilename) { writer ->
            writer.openBlock(
                "let smithy_api__EnumUnit_schema = { \$N<\$L.EnumUnit>(",
                ") }()",
                SmithyReadWriteTypes.Schema,
                namespaceName,
            ) {
                writer.write("type: .structure")
            }
        }
    }
}

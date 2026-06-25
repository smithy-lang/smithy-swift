package software.amazon.smithy.swift.codegen.swiftmodules

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.SwiftDeclaration
import software.amazon.smithy.swift.codegen.SwiftDependency

object SmithyTestUtilTypes {
    val TestInitializer = runtimeSymbol("TestInitializer", SwiftDeclaration.ENUM)
    val TestBaseError = runtimeSymbol("TestBaseError", SwiftDeclaration.STRUCT)
    val TestCheckError = runtimeSymbol("TestCheckError", SwiftDeclaration.ENUM)
    val dummyIdentityResolver = runtimeSymbol("dummyIdentityResolver", SwiftDeclaration.FUNC)
    val ProtocolTestRetryStrategyOptions = runtimeSymbol("ProtocolTestRetryStrategyOptions", SwiftDeclaration.ENUM)
    val SerdeBenchmarker = runtimeSymbol("SerdeBenchmarker", SwiftDeclaration.STRUCT)
    val SerdeBenchmarkTelemetryProvider = runtimeSymbol("SerdeBenchmarkTelemetryProvider", SwiftDeclaration.CLASS)
}

private fun runtimeSymbol(
    name: String,
    declaration: SwiftDeclaration? = null,
): Symbol =
    SwiftSymbol.make(
        name,
        declaration,
        SwiftDependency.SMITHY_TEST_UTIL,
        emptyList(),
        emptyList(),
    )

package software.amazon.smithy.swift.codegen.integration.serde.formurl

fun String.indexAdvancedBy1(indexVariableName: String): String {
    return "$this.\\($indexVariableName.advanced(by: 1))"
}

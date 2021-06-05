package software.amazon.smithy.swift.codegen.integration.serde.formurl

interface FormURLEncodeCustomizable {
    fun alwaysUsesFlattenedCollections(): Boolean
}

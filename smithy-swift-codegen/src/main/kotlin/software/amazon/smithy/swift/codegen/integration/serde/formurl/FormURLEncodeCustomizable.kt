package software.amazon.smithy.swift.codegen.integration.serde.formurl

import software.amazon.smithy.model.shapes.Shape

interface FormURLEncodeCustomizable {
    fun alwaysUsesFlattenedCollections(): Boolean
    fun customNameTraitGenerator(memberShape: Shape, defaultName: String): String
}

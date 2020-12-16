/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import io.kotest.matchers.string.shouldContain
import kotlin.streams.toList
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Test
import software.amazon.smithy.build.MockManifest
import software.amazon.smithy.codegen.core.SymbolDependency
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.node.Node

class PodSpecGeneratorTests : TestsBase() {

    @Test
    fun `it renders podspec with dependencies`() {
        val model = createModelFromSmithy("simple-service-with-operation-and-dependency.smithy")
        val homepage = "https://docs.amplify.aws/"
        val settings = SwiftSettings.from(model, Node.objectNodeBuilder()
            .withMember("module", Node.from("example"))
            .withMember("moduleVersion", Node.from("1.0.0"))
            .withMember("homepage", Node.from(homepage))
            .withMember("author", Node.from("Amazon Web Services"))
            .withMember("gitRepo", Node.from("https://github.com/aws-amplify/amplify-codegen.git"))
            .withMember("swiftVersion", Node.from("5.1.0"))
            .build())

        val manifest = MockManifest()
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "example")
        val mockDependencies = getMockDependenciesFromModel(model, provider).toSet()

        writePodspec(settings, manifest, mockDependencies)
        val podspec = manifest.getFileString("/example.podspec").get()
        assertNotNull(podspec)
        podspec.shouldContain("spec.dependency 'ComplexModule', '0.0.5'")
        podspec.shouldContain("spec.dependency 'ClientRuntime', '0.1.0'")
        podspec.shouldContain("spec.homepage     = '$homepage'")
    }

    fun getMockDependenciesFromModel(model: Model, symbolProvider: SymbolProvider): MutableList<SymbolDependency> {
        val mockDependencies = mutableListOf<SymbolDependency>()

        // BigInteger and Document types have dependencies on other packages
        val bigIntTypeMember = model.shapes().filter { it.isBigIntegerShape }.toList().first()
        mockDependencies.addAll(symbolProvider.toSymbol(bigIntTypeMember).dependencies)

        val documentTypeMember = model.shapes().filter { it.isDocumentShape }.toList().first()
        mockDependencies.addAll(symbolProvider.toSymbol(documentTypeMember).dependencies)
        return mockDependencies
    }
}

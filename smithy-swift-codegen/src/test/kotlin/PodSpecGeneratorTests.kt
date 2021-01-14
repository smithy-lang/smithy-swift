/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContain
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Test
import software.amazon.smithy.build.MockManifest
import software.amazon.smithy.codegen.core.SymbolDependency
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.swift.codegen.SwiftCodegenPlugin
import software.amazon.smithy.swift.codegen.writePodspec
import kotlin.streams.toList

class PodSpecGeneratorTests {

    @Test
    fun `it renders podspec with dependencies`() {
        val model = "simple-service-with-operation-and-dependency.smithy".asSmithyModel()
        val settings = model.defaultSettings(moduleName = "example")

        val manifest = MockManifest()
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "example")
        val mockDependencies = getMockDependenciesFromModel(model, provider).toSet()

        writePodspec(settings, manifest, mockDependencies)
        val podspec = manifest.getFileString("/example.podspec").get()
        assertNotNull(podspec)
        podspec.shouldContain("spec.dependency 'ComplexModule', '0.0.5'")
        podspec.shouldContain("spec.dependency 'ClientRuntime', '0.1.0'")
        podspec.shouldContain("spec.homepage     = 'https://docs.amplify.aws/'")
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

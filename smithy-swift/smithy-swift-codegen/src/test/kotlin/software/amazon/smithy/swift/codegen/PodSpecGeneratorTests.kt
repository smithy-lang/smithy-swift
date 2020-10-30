/*
 *
 *  * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  *
 *  * Licensed under the Apache License, Version 2.0 (the "License").
 *  * You may not use this file except in compliance with the License.
 *  * A copy of the License is located at
 *  *
 *  *  http://aws.amazon.com/apache2.0
 *  *
 *  * or in the "license" file accompanying this file. This file is distributed
 *  * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 *  * express or implied. See the License for the specific language governing
 *  * permissions and limitations under the License.
 *
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
        podspec.shouldContain("spec.dependency 'Numerics', '0.0.5'")
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

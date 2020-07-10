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

class PackageManifestGeneratorTests : TestsBase() {

    private val model: Model
    private val settings: SwiftSettings
    private val manifest: MockManifest
    private val mockDependencies: MutableList<SymbolDependency>

    init {
        model = createModelFromSmithy("simple-service-with-operation-and-dependency.smithy")
        settings = SwiftSettings.from(
            model,
            Node.objectNodeBuilder()
                .withMember("module", Node.from("MockSDK"))
                .withMember("moduleVersion", Node.from("1.0.0"))
                .withMember("homepage", Node.from("https://docs.amplify.aws/"))
                .withMember("author", Node.from("Amazon Web Services"))
                .withMember("gitRepo", Node.from("https://github.com/aws-amplify/amplify-codegen.git"))
                .build()
        )
        manifest = MockManifest()
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "MockSDK")
        mockDependencies = getMockDependenciesFromModel(model, provider)
    }

    @Test
    fun `it renders package manifest file with correct dependencies block`() {
        writePackageManifest(settings, manifest, mockDependencies)
        val packageManifest = manifest.getFileString("Package.swift").get()
        assertNotNull(packageManifest)
        packageManifest.shouldContain(
         "dependencies: [\n" +
                 "        .package(\n" +
                 "            url: \"https://github.com/mkrd/Swift-Big-Integer.git\",\n" +
                 "            from: 2.0\n" +
                 "        ),\n" +
                 "        .package(path: \"../../../../../../ClientRuntime\"),\n" +
                 "    ]")
    }

    @Test
    fun `it renders package manifest file with correct platforms block`() {
        writePackageManifest(settings, manifest, mockDependencies)
        val packageManifest = manifest.getFileString("Package.swift").get()
        assertNotNull(packageManifest)
        packageManifest.shouldContain(
            "platforms: [\n" +
                    "        .macOS(.v10_15), .iOS(.v13)\n" +
                    "    ]")
    }

    @Test
    fun `it renders package manifest file with correct products block`() {
        writePackageManifest(settings, manifest, mockDependencies)
        val packageManifest = manifest.getFileString("Package.swift").get()
        assertNotNull(packageManifest)
        packageManifest.shouldContain(
            "products: [\n" +
                    "        .library(name: \"MockSDK\", targets: [\"MockSDK\"])\n" +
                    "    ]")
    }

    @Test
    fun `it renders package manifest file with correct targets block`() {
        writePackageManifest(settings, manifest, mockDependencies)
        val packageManifest = manifest.getFileString("Package.swift").get()
        assertNotNull(packageManifest)
        packageManifest.shouldContain(
            "targets: [\n" +
                    "        .target(\n" +
                    "            name: \"MockSDK\",\n" +
                    "            dependencies: [\n" +
                    "                \"BigNumber\", \"ClientRuntime\"\n" +
                    "            ],\n" +
                    "            path: \"./MockSDK\"\n" +
                    "        )\n" +
                    "    ]")
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

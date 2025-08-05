package software.amazon.smithy.swift.codegen.manifestanddocs

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.string.shouldStartWith
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.PackageManifestGenerator
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.TestContext
import software.amazon.smithy.swift.codegen.defaultSettings
import software.amazon.smithy.swift.codegen.protocolgeneratormocks.MockHTTPAWSJson11ProtocolGenerator

class PackageManifestGeneratorTests {
    private val testContext = setupTests("simple-service-with-operation-and-dependency.smithy", "smithy.example#Example")

    @Test
    fun `it starts with a swift-tools-version statement`() {
        val packageManifest = testContext.manifest.getFileString("Package.swift").get()
        assertNotNull(packageManifest)
        packageManifest.shouldStartWith("// swift-tools-version: 5.5.0")
    }

    @Test
    fun `it renders package manifest file with macOS and iOS platforms block`() {
        val packageManifest = testContext.manifest.getFileString("Package.swift").get()
        assertNotNull(packageManifest)
        val expected = """
    platforms: [
        .macOS(.v12), .iOS(.v13)
    ],
"""
        packageManifest.shouldContain(expected)
    }

    @Test
    fun `it renders package manifest file with single library in product block`() {
        val packageManifest = testContext.manifest.getFileString("Package.swift").get()
        assertNotNull(packageManifest)
        val expected = """
    products: [
        .library(name: "MockSDK", targets: ["MockSDK"])
    ],
"""
        packageManifest.shouldContain(expected)
    }

    @Test
    fun `it renders package manifest file with dependencies`() {
        val packageManifest = testContext.manifest.getFileString("Package.swift").get()
        assertNotNull(packageManifest)
        val expected = """
    dependencies: [
        .package(
            url: "https://github.com/smithy-lang/smithy-swift",
            exact: "0.0.1"
        ),
    ],
"""
        packageManifest.shouldContain(expected)
    }

    @Test
    fun `it renders package manifest file with target and test target`() {
        val packageManifest = testContext.manifest.getFileString("Package.swift").get()
        assertNotNull(packageManifest)
        val expected = """
    targets: [
        .target(
            name: "MockSDK",
            dependencies: [
                .product(
                    name: "ClientRuntime",
                    package: "smithy-swift"
                ),
            ]
        ),
        .testTarget(
            name: "MockSDKTests",
            dependencies: [
                "MockSDK",
                .product(
                    name: "SmithyTestUtil",
                    package: "smithy-swift"
                ),
            ]
        )
    ]
"""
        packageManifest.shouldContain(expected)
    }

    private fun setupTests(
        smithyFile: String,
        serviceShapeId: String,
    ): TestContext {
        val context =
            TestContext.initContextFrom(smithyFile, serviceShapeId, MockHTTPAWSJson11ProtocolGenerator()) { model ->
                model.defaultSettings(serviceShapeId, "MockSDK", "2019-12-16", "MockSDKID")
            }
        context.generationCtx.delegator.useFileWriter("xyz.swift") { writer ->
            writer.addDependency(SwiftDependency.CLIENT_RUNTIME)
        }
        PackageManifestGenerator(context.generationCtx).writePackageManifest(context.generationCtx.delegator.dependencies)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContain
import mocks.MockHTTPAWSJson11ProtocolGenerator
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.PackageManifestGenerator

class PackageManifestGeneratorTests {
    private val testContext = setupTests("simple-service-with-operation-and-dependency.smithy", "smithy.example#Example")

    @Test
    fun `it renders package manifest file with macOS and iOS platforms block`() {
        val packageManifest = testContext.manifest.getFileString("Package.swift").get()
        assertNotNull(packageManifest)
        packageManifest.shouldContain(
            "platforms: [\n" +
                "        .macOS(.v10_15), .iOS(.v13)\n" +
                "    ]"
        )
    }

    @Test
    fun `it renders package manifest file with single library in product block`() {
        val packageManifest = testContext.manifest.getFileString("Package.swift").get()
        assertNotNull(packageManifest)
        packageManifest.shouldContain(
            "products: [\n" +
                "        .library(name: \"MockSDK\", targets: [\"MockSDK\"])\n" +
                "    ]"
        )
    }

    @Test
    fun `it renders package manifest file with target and test target`() {
        println(testContext.manifest.files)
        val packageManifest = testContext.manifest.getFileString("Package.swift").get()
        assertNotNull(packageManifest)
        val expected = """
    targets: [
        .target(
            name: "MockSDK",
            dependencies: [
            ]
        ),
        .testTarget(
            name: "MockSDKTests",
            dependencies: [
                "MockSDK",
                .product(name: "SmithyTestUtil", package: "smithy-swift"),
            ]
        )
    ]
"""
        packageManifest.shouldContain(expected)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId, MockHTTPAWSJson11ProtocolGenerator()) { model ->
            model.defaultSettings(serviceShapeId, "MockSDK", "2019-12-16", "MockSDKID")
        }
        PackageManifestGenerator(context.generationCtx).writePackageManifest(context.generationCtx.delegator.dependencies)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}

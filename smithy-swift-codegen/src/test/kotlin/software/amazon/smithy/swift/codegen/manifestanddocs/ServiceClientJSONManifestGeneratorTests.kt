package software.amazon.smithy.swift.codegen.manifestanddocs

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContain
import org.junit.jupiter.api.Assertions.assertNotNull
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.DependencyJSONGenerator
import software.amazon.smithy.swift.codegen.TestContext
import software.amazon.smithy.swift.codegen.defaultSettings
import software.amazon.smithy.swift.codegen.protocolgeneratormocks.MockHTTPAWSJson11ProtocolGenerator

class ServiceClientJSONManifestGeneratorTests {
    private val testContext = setupTests("simple-service-with-operation-and-dependency.smithy", "smithy.example#Example")

    @Test
    fun `it renders package manifest JSON with dependencies`() {
        val packageManifest = testContext.manifest.getFileString("Dependencies.json").get()
        assertNotNull(packageManifest)
        val expected = """[

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
        DependencyJSONGenerator(context.generationCtx).writePackageJSON(context.generationCtx.delegator.dependencies)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}

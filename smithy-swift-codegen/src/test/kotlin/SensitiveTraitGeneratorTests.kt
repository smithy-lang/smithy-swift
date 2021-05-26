/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.build.MockManifest
import software.amazon.smithy.swift.codegen.SwiftCodegenPlugin

class SensitiveTraitGeneratorTests {
    @Test
    fun `SensitiveTraitInRequestInput+CustomDebugStringConvertible`() {
        val manifest = setupTest()
        var extensionWithSensitiveTrait = manifest
            .getFileString("example/models/SensitiveTraitInRequestInput+CustomDebugStringConvertible.swift").get()
        extensionWithSensitiveTrait.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension SensitiveTraitInRequestInput: CustomDebugStringConvertible {
                public var debugDescription: String {
                    "SensitiveTraitInRequestInput(foo: \(String(describing: foo)), baz: \"CONTENT_REDACTED\")"}
            }
            """.trimIndent()
        extensionWithSensitiveTrait.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `SensitiveTraitInRequestOutput+CustomDebugStringConvertible`() {
        val manifest = setupTest()
        var extensionWithSensitiveTrait = manifest
            .getFileString("example/models/SensitiveTraitInRequestOutput+CustomDebugStringConvertible.swift").get()
        extensionWithSensitiveTrait.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension SensitiveTraitInRequestOutput: CustomDebugStringConvertible {
                public var debugDescription: String {
                    "CONTENT_REDACTED"
                }
            }
            """.trimIndent()
        extensionWithSensitiveTrait.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `NoSensitiveMemberStruct+CustomDebugStringConvertible`() {
        val manifest = setupTest()
        var extensionWithSensitiveTrait = manifest
            .getFileString("example/models/SensitiveTraitTestRequestInput+CustomDebugStringConvertible.swift").get()
        extensionWithSensitiveTrait.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension SensitiveTraitTestRequestInput: CustomDebugStringConvertible {
                public var debugDescription: String {
                    "SensitiveTraitTestRequestInput(bar: \(String(describing: bar)), baz: \(String(describing: baz)), foo: \(String(describing: foo)))"}
            }
            """.trimIndent()
        extensionWithSensitiveTrait.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `AllSensitiveMemberStruct+CustomDebugStringConvertible`() {
        val manifest = setupTest()
        var extensionWithSensitiveTrait = manifest
            .getFileString("example/models/SensitiveTraitTestRequestOutput+CustomDebugStringConvertible.swift").get()
        extensionWithSensitiveTrait.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension SensitiveTraitTestRequestOutput: CustomDebugStringConvertible {
                public var debugDescription: String {
                    "SensitiveTraitTestRequestOutput(bar: \"CONTENT_REDACTED\", baz: \"CONTENT_REDACTED\", foo: \"CONTENT_REDACTED\")"}
            }
            """.trimIndent()
        extensionWithSensitiveTrait.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTest(): MockManifest {
        val model = javaClass.getResource("sensitive-trait-test.smithy").asSmithy()
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest, "smithy.example#Example")
        SwiftCodegenPlugin().execute(context)
        return manifest
    }
}

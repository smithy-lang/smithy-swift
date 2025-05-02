package software.amazon.smithy.swift.codegen.traits

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.build.MockManifest
import software.amazon.smithy.swift.codegen.SwiftCodegenPlugin
import software.amazon.smithy.swift.codegen.asSmithy
import software.amazon.smithy.swift.codegen.buildMockPluginContext
import software.amazon.smithy.swift.codegen.shouldSyntacticSanityCheck

class SensitiveTraitGeneratorTests {
    @Test
    fun `SensitiveTraitInRequestInput+CustomDebugStringConvertible`() {
        val manifest = setupTest()
        var extensionWithSensitiveTrait =
            manifest
                .getFileString("Sources/example/models/SensitiveTraitInRequestInput+CustomDebugStringConvertible.swift")
                .get()
        extensionWithSensitiveTrait.shouldSyntacticSanityCheck()
        val expectedContents = """
extension SensitiveTraitInRequestInput: Swift.CustomDebugStringConvertible {
    public var debugDescription: Swift.String {
        "SensitiveTraitInRequestInput(foo: \(Swift.String(describing: foo)), baz: \"CONTENT_REDACTED\")"}
}
"""
        extensionWithSensitiveTrait.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `SensitiveTraitInRequestOutput+CustomDebugStringConvertible`() {
        val manifest = setupTest()
        var extensionWithSensitiveTrait =
            manifest
                .getFileString("Sources/example/models/SensitiveTraitInRequestOutput+CustomDebugStringConvertible.swift")
                .get()
        extensionWithSensitiveTrait.shouldSyntacticSanityCheck()
        val expectedContents = """
extension SensitiveTraitInRequestOutput: Swift.CustomDebugStringConvertible {
    public var debugDescription: Swift.String {
        "CONTENT_REDACTED"
    }
}
"""
        extensionWithSensitiveTrait.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `AllSensitiveMemberStruct+CustomDebugStringConvertible`() {
        val manifest = setupTest()
        var extensionWithSensitiveTrait =
            manifest
                .getFileString("Sources/example/models/SensitiveTraitTestRequestOutput+CustomDebugStringConvertible.swift")
                .get()
        extensionWithSensitiveTrait.shouldSyntacticSanityCheck()
        val expectedContents = """
extension SensitiveTraitTestRequestOutput: Swift.CustomDebugStringConvertible {
    public var debugDescription: Swift.String {
        "SensitiveTraitTestRequestOutput(bar: \"CONTENT_REDACTED\", baz: \"CONTENT_REDACTED\", foo: \"CONTENT_REDACTED\")"}
}
"""
        extensionWithSensitiveTrait.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTest(): MockManifest {
        val model = javaClass.classLoader.getResource("sensitive-trait-test.smithy").asSmithy()
        val manifest = MockManifest()
        val context = buildMockPluginContext(model, manifest, "smithy.example#Example")
        SwiftCodegenPlugin().execute(context)
        return manifest
    }
}

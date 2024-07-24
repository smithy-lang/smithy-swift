/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContain
import org.junit.jupiter.api.Test
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.Middleware
import software.amazon.smithy.swift.codegen.MiddlewareGenerator
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.swiftmodules.SwiftTypes

class MiddlewareGeneratorTests {
    @Test
    fun `generates middleware structs`() {
        val writer = SwiftWriter("MockPackage")
        val testSymbol = Symbol.builder().name("Test").build()
        val mockMiddleware = MockMiddleware(writer, testSymbol)
        val generator = MiddlewareGenerator(writer, mockMiddleware)
        generator.generate()
        val contents = writer.toString()
        val expectedGeneratedStructure = """
public struct TestMiddleware {
    public let id: Swift.String = "TestMiddleware"

    let test: Swift.String

    public init() {}
}
"""
        contents.shouldContain(expectedGeneratedStructure)
    }
}

class MockMiddleware(private val writer: SwiftWriter, symbol: Symbol) : Middleware(writer, symbol) {
    override val properties = mutableMapOf("test" to SwiftTypes.String)
    override fun generateInit() {
        writer.write("public init() {}")
    }
}

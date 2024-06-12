/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContain
import org.junit.jupiter.api.Test
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.Middleware
import software.amazon.smithy.swift.codegen.MiddlewareGenerator
import software.amazon.smithy.swift.codegen.OperationStep
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
public struct TestMiddleware: ClientRuntime.Middleware {
    public let id: Swift.String = "TestMiddleware"

    let test: Swift.String

    public init() {}

    public func handle<H>(context: Smithy.Context,
                  input: Swift.String,
                  next: H) async throws -> ClientRuntime.OperationOutput<Swift.String>
    where H: ClientRuntime.Handler,
    Self.MInput == H.Input,
    Self.MOutput == H.Output
    {
        print("this is a \(test)")
        return try await next.handle(context: context, input: input)
    }

    public typealias MInput = Swift.String
    public typealias MOutput = ClientRuntime.OperationOutput<Swift.String>
}
"""
        contents.shouldContain(expectedGeneratedStructure)
    }
}

class MockOperationStep(outputSymbol: Symbol, outputErrorSymbol: Symbol) : OperationStep(outputSymbol, outputErrorSymbol) {
    override val inputType: Symbol = SwiftTypes.String
}

class MockMiddleware(private val writer: SwiftWriter, symbol: Symbol) : Middleware(
    writer, symbol,
    MockOperationStep(
        SwiftTypes.String, SwiftTypes.Error
    )
) {
    override val properties = mutableMapOf("test" to SwiftTypes.String)
    override fun generateMiddlewareClosure() {
        writer.write("print(\"this is a \\(test)\")")
    }

    override fun generateInit() {
        writer.write("public init() {}")
    }
}

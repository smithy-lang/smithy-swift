/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.protocoltests.traits.HttpMessageTestCase
import software.amazon.smithy.swift.codegen.SwiftWriter

/**
 * Abstract base implementation for protocol test generators to extend in order to generate HttpMessageTestCase
 * specific protocol tests.
 *
 * @param T Specific HttpMessageTestCase the protocol test generator is for.
 */
abstract class HttpProtocolUnitTestGenerator<T : HttpMessageTestCase>
protected constructor(builder: Builder<T>) {

    protected val symbolProvider: SymbolProvider = builder.symbolProvider!!
    protected var model: Model = builder.model!!
    private val testCases: List<T> = builder.testCases!!
    protected val operation: OperationShape = builder.operation!!
    protected val writer: SwiftWriter = builder.writer!!
    protected val httpProtocolCustomizable = builder.httpProtocolCustomizable!!
    protected val serdeContext = builder.serdeContext!!
    protected val serviceName: String = builder.serviceName!!
    abstract val baseTestClassName: String

    /**
     * Render a test class and unit tests for the specified [testCases]
     */
    fun renderTestClass(testClassName: String) {
        writer.write("")
            .openBlock("class $testClassName: $baseTestClassName {")
            // TODO:: Replace host appropriately
            .write("let host = \"my-api.us-east-2.amazonaws.com\"")
            .call {
                for (test in testCases) {
                    renderTestFunction(test)
                }
            }
            .closeBlock("}")
    }

    /**
     * Write a single unit test function using the given [writer]
     */
    private fun renderTestFunction(test: T) {
        test.documentation.ifPresent {
            writer.writeDocs(it)
        }

        writer.openBlock("func test${test.id}() {", "}") {
            renderTestBody(test)
        }
    }

    /**
     * Render the body of a unit test
     */
    protected abstract fun renderTestBody(test: T)

    data class SerdeContext(
        val protocolEncoder: String,
        val protocolDecoder: String,
        val defaultTimestampFormat: String? = null
    )

    abstract class Builder<T : HttpMessageTestCase> {
        var symbolProvider: SymbolProvider? = null
        var model: Model? = null
        var testCases: List<T>? = null
        var operation: OperationShape? = null
        var writer: SwiftWriter? = null
        var serviceName: String? = null
        var httpProtocolCustomizable: HttpProtocolCustomizable? = null
        var serdeContext: SerdeContext? = null

        fun symbolProvider(provider: SymbolProvider): Builder<T> = apply { this.symbolProvider = provider }
        fun model(model: Model): Builder<T> = apply { this.model = model }
        fun testCases(testCases: List<T>): Builder<T> = apply { this.testCases = testCases }
        fun operation(operation: OperationShape): Builder<T> = apply { this.operation = operation }
        fun writer(writer: SwiftWriter): Builder<T> = apply { this.writer = writer }
        fun serviceName(serviceName: String): Builder<T> = apply { this.serviceName = serviceName }
        fun httpProtocolCustomizable(httpProtocolCustomizable: HttpProtocolCustomizable): Builder<T> = apply { this.httpProtocolCustomizable = httpProtocolCustomizable }
        fun serdeContext(serdeContext: SerdeContext): Builder<T> = apply { this.serdeContext = serdeContext }
        abstract fun build(): HttpProtocolUnitTestGenerator<T>
    }
}

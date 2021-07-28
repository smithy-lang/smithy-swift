/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.model.knowledge.OperationIndex
import software.amazon.smithy.model.knowledge.TopDownIndex
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.protocoltests.traits.AppliesTo
import software.amazon.smithy.protocoltests.traits.HttpMessageTestCase
import software.amazon.smithy.protocoltests.traits.HttpRequestTestsTrait
import software.amazon.smithy.protocoltests.traits.HttpResponseTestsTrait
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.model.capitalizedName
import software.amazon.smithy.swift.codegen.getOrNull
import java.util.TreeSet
import java.util.logging.Logger

/**
 * Generates protocol unit tests for the HTTP protocol from smithy models.
 */
class HttpProtocolTestGenerator(
    private val ctx: ProtocolGenerator.GenerationContext,
    private val requestTestBuilder: HttpProtocolUnitTestRequestGenerator.Builder,
    private val responseTestBuilder: HttpProtocolUnitTestResponseGenerator.Builder,
    private val errorTestBuilder: HttpProtocolUnitTestErrorGenerator.Builder,
    private val httpProtocolCustomizable: HttpProtocolCustomizable,
    private val serdeContext: HttpProtocolUnitTestGenerator.SerdeContext,
    // list of test IDs to ignore/skip
    private val testsToIgnore: Set<String> = setOf()
) {
    private val LOGGER = Logger.getLogger(javaClass.name)

    /**
     * Generates the API HTTP protocol tests defined in the smithy model.
     */
    fun generateProtocolTests() {
        val topDownIndex: TopDownIndex = TopDownIndex.of(ctx.model)
        val serviceSymbol = ctx.symbolProvider.toSymbol(ctx.service)

        for (operation in TreeSet(topDownIndex.getContainedOperations(ctx.service).filterNot(::serverOnly))) {
            renderRequestTests(operation, serviceSymbol)
            renderResponseTests(operation, serviceSymbol)
            renderErrorTestCases(operation, serviceSymbol)
        }
    }

    private fun renderRequestTests(operation: OperationShape, serviceSymbol: Symbol) {
        val tempTestCases = operation.getTrait(HttpRequestTestsTrait::class.java)
            .getOrNull()
            ?.getTestCasesFor(AppliesTo.CLIENT)
            .orEmpty()
        val requestTestCases = filterProtocolTestCases(tempTestCases)
        if (requestTestCases.isNotEmpty()) {
            val testClassName = "${operation.capitalizedName()}RequestTest"
            val testFilename = "./${ctx.settings.moduleName}Tests/$testClassName.swift"
            ctx.delegator.useTestFileWriter(testFilename, ctx.settings.moduleName) { writer ->
                LOGGER.fine("Generating request protocol test cases for ${operation.id}")

                writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
                writer.addImport(ctx.settings.moduleName, true)
                writer.addImport(SwiftDependency.SMITHY_TEST_UTIL.target)
                writer.addImport(SwiftDependency.XCTest.target)

                requestTestBuilder
                    .writer(writer)
                    .model(ctx.model)
                    .symbolProvider(ctx.symbolProvider)
                    .operation(operation)
                    .serviceName(serviceSymbol.name)
                    .testCases(requestTestCases)
                    .httpProtocolCustomizable(httpProtocolCustomizable)
                    .serdeContext(serdeContext)
                    .build()
                    .renderTestClass(testClassName)
            }
        }
    }

    private fun renderResponseTests(operation: OperationShape, serviceSymbol: Symbol) {
        val tempResponseTests = operation.getTrait(HttpResponseTestsTrait::class.java)
            .getOrNull()
            ?.getTestCasesFor(AppliesTo.CLIENT)
            .orEmpty()
        val responseTestCases = filterProtocolTestCases(tempResponseTests)
        if (responseTestCases.isNotEmpty()) {
            val testClassName = "${operation.id.name.capitalize()}ResponseTest"
            val testFilename = "./${ctx.settings.moduleName}Tests/$testClassName.swift"
            ctx.delegator.useTestFileWriter(testFilename, ctx.settings.moduleName) { writer ->
                LOGGER.fine("Generating response protocol test cases for ${operation.id}")

                writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
                writer.addImport(ctx.settings.moduleName, true)
                writer.addImport(SwiftDependency.SMITHY_TEST_UTIL.target)
                writer.addImport(SwiftDependency.XCTest.target)

                responseTestBuilder
                    .writer(writer)
                    .model(ctx.model)
                    .symbolProvider(ctx.symbolProvider)
                    .operation(operation)
                    .serviceName(serviceSymbol.name)
                    .testCases(responseTestCases)
                    .httpProtocolCustomizable(httpProtocolCustomizable)
                    .serdeContext(serdeContext)
                    .build()
                    .renderTestClass(testClassName)
            }
        }
    }

    private fun renderErrorTestCases(operation: OperationShape, serviceSymbol: Symbol) {
        val operationIndex: OperationIndex = OperationIndex.of(ctx.model)

        for (error in operationIndex.getErrors(operation).filterNot(::serverOnly)) {
            val tempTestCases = error.getTrait(HttpResponseTestsTrait::class.java)
                .getOrNull()
                ?.getTestCasesFor(AppliesTo.CLIENT)
                .orEmpty()
            val testCases = filterProtocolTestCases(tempTestCases)
            if (testCases.isNotEmpty()) {
                // multiple error (tests) may be associated with a single operation,
                // use the operation name + error name as the class name
                val opName = operation.id.name.capitalize()
                val testClassName = "${opName}${error.capitalizedName()}Test"
                val testFilename = "./${ctx.settings.moduleName}Tests/${opName}ErrorTest.swift"
                ctx.delegator.useTestFileWriter(testFilename, ctx.settings.moduleName) { writer ->
                    LOGGER.fine("Generating error protocol test cases for ${operation.id}")

                    writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
                    writer.addImport(ctx.settings.moduleName, true)
                    writer.addImport(SwiftDependency.SMITHY_TEST_UTIL.target)
                    writer.addImport(SwiftDependency.XCTest.target)

                    errorTestBuilder
                        .error(error)
                        .writer(writer)
                        .model(ctx.model)
                        .symbolProvider(ctx.symbolProvider)
                        .operation(operation)
                        .serviceName(serviceSymbol.name)
                        .testCases(testCases)
                        .httpProtocolCustomizable(httpProtocolCustomizable)
                        .serdeContext(serdeContext)
                        .build()
                        .renderTestClass(testClassName)
                }
            }
        }
    }

    private fun <T : HttpMessageTestCase> filterProtocolTestCases(testCases: List<T>): List<T> = testCases.filter {
        it.protocol == ctx.protocol && it.id !in testsToIgnore
    }
}

private fun serverOnly(shape: Shape): Boolean = shape.hasTag("server-only")

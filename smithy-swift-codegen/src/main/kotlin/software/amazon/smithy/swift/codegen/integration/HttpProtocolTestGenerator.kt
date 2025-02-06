/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.model.knowledge.OperationIndex
import software.amazon.smithy.model.knowledge.TopDownIndex
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.protocoltests.traits.AppliesTo
import software.amazon.smithy.protocoltests.traits.HttpMessageTestCase
import software.amazon.smithy.protocoltests.traits.HttpRequestTestsTrait
import software.amazon.smithy.protocoltests.traits.HttpResponseTestsTrait
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.model.toUpperCamelCase
import software.amazon.smithy.swift.codegen.testModuleName
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
    private val httpProtocolCustomizable: HTTPProtocolCustomizable,
    private val httpBindingResolver: HttpBindingResolver,
    // list of test IDs to ignore/skip
    private val testsToIgnore: Set<String> = setOf(),
    private val tagsToIgnore: Set<String> = setOf(),
) {
    @Suppress("ktlint:standard:property-naming")
    private val LOGGER = Logger.getLogger(javaClass.name)

    /**
     * Generates the API HTTP protocol tests defined in the smithy model.
     */
    fun generateProtocolTests(): Int {
        val topDownIndex: TopDownIndex = TopDownIndex.of(ctx.model)
        var numTests = 0
        for (operation in TreeSet(topDownIndex.getContainedOperations(ctx.service).filterNot(::serverOnly))) {
            numTests += renderRequestTests(operation)
            numTests += renderResponseTests(operation)
            numTests += renderErrorTestCases(operation)
        }
        return numTests
    }

    private fun renderRequestTests(operation: OperationShape): Int {
        val serviceSymbol = ctx.symbolProvider.toSymbol(ctx.service)
        val tempTestCases =
            operation
                .getTrait(HttpRequestTestsTrait::class.java)
                .orElse(null)
                ?.getTestCasesFor(AppliesTo.CLIENT)
                .orEmpty()
        val requestTestCases = filterProtocolTestCases(filterProtocolTestCasesByTags(tempTestCases))
        if (requestTestCases.isNotEmpty()) {
            val testClassName = "${operation.toUpperCamelCase()}RequestTest"
            val testFilename = "Tests/${ctx.settings.testModuleName}/$testClassName.swift"
            ctx.delegator.useTestFileWriter(testFilename, ctx.settings.moduleName) { writer ->
                LOGGER.fine("Generating request protocol test cases for ${operation.id}")
                writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
                writer.addImport(ctx.settings.moduleName, true)
                writer.addImport(SwiftDependency.SMITHY_TEST_UTIL.target)
                writer.addImport(SwiftDependency.XCTest.target)
                requestTestBuilder
                    .ctx(ctx)
                    .writer(writer)
                    .model(ctx.model)
                    .symbolProvider(ctx.symbolProvider)
                    .operation(operation)
                    .serviceName(serviceSymbol.name)
                    .testCases(requestTestCases)
                    .httpProtocolCustomizable(httpProtocolCustomizable)
                    .httpBindingResolver(httpBindingResolver)
                    .build()
                    .renderTestClass(testClassName)
            }
        }
        return requestTestCases.count()
    }

    private fun renderResponseTests(operation: OperationShape): Int {
        val serviceSymbol = ctx.symbolProvider.toSymbol(ctx.service)
        val tempResponseTests =
            operation
                .getTrait(HttpResponseTestsTrait::class.java)
                .orElse(null)
                ?.getTestCasesFor(AppliesTo.CLIENT)
                .orEmpty()
        val responseTestCases = filterProtocolTestCases(filterProtocolTestCasesByTags(tempResponseTests))
        if (responseTestCases.isNotEmpty()) {
            val testClassName = "${operation.id.name.capitalize()}ResponseTest"
            val testFilename = "Tests/${ctx.settings.testModuleName}/$testClassName.swift"
            ctx.delegator.useTestFileWriter(testFilename, ctx.settings.moduleName) { writer ->
                LOGGER.fine("Generating response protocol test cases for ${operation.id}")
                writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
                writer.addImport(ctx.settings.moduleName, true)
                writer.addImport(SwiftDependency.SMITHY_TEST_UTIL.target)
                writer.addImport(SwiftDependency.XCTest.target)
                responseTestBuilder
                    .ctx(ctx)
                    .writer(writer)
                    .model(ctx.model)
                    .symbolProvider(ctx.symbolProvider)
                    .operation(operation)
                    .serviceName(serviceSymbol.name)
                    .testCases(responseTestCases)
                    .httpProtocolCustomizable(httpProtocolCustomizable)
                    .httpBindingResolver(httpBindingResolver)
                    .build()
                    .renderTestClass(testClassName)
            }
        }
        return responseTestCases.count()
    }

    private fun renderErrorTestCases(operation: OperationShape): Int {
        val serviceSymbol = ctx.symbolProvider.toSymbol(ctx.service)
        val operationIndex: OperationIndex = OperationIndex.of(ctx.model)
        var numTestCases = 0
        for (error in operationIndex.getErrors(operation).filterNot(::serverOnly)) {
            val tempTestCases =
                error
                    .getTrait(HttpResponseTestsTrait::class.java)
                    .orElse(null)
                    ?.getTestCasesFor(AppliesTo.CLIENT)
                    .orEmpty()
            val testCases = filterProtocolTestCases(filterProtocolTestCasesByTags(tempTestCases))
            numTestCases += testCases.count()
            if (testCases.isNotEmpty()) {
                // multiple error (tests) may be associated with a single operation,
                // use the operation name + error name as the class name
                val opName = operation.id.name.capitalize()
                val testClassName = "${opName}${error.toUpperCamelCase()}Test"
                val testFilename = "Tests/${ctx.settings.testModuleName}/${opName}ErrorTest.swift"
                ctx.delegator.useTestFileWriter(testFilename, ctx.settings.moduleName) { writer ->
                    LOGGER.fine("Generating error protocol test cases for ${operation.id}")
                    writer.addImport(SwiftDependency.CLIENT_RUNTIME.target)
                    writer.addImport(ctx.settings.moduleName, true)
                    writer.addImport(SwiftDependency.SMITHY_TEST_UTIL.target)
                    writer.addImport(SwiftDependency.XCTest.target)
                    errorTestBuilder
                        .error(error)
                        .ctx(ctx)
                        .writer(writer)
                        .model(ctx.model)
                        .symbolProvider(ctx.symbolProvider)
                        .operation(operation)
                        .serviceName(serviceSymbol.name)
                        .testCases(testCases)
                        .httpProtocolCustomizable(httpProtocolCustomizable)
                        .httpBindingResolver(httpBindingResolver)
                        .build()
                        .renderTestClass(testClassName)
                }
            }
        }
        return numTestCases
    }

    private fun <T : HttpMessageTestCase> filterProtocolTestCases(testCases: List<T>): List<T> =
        testCases.filter {
            it.protocol == ctx.protocol && it.id !in testsToIgnore
        }

    private fun <T : HttpMessageTestCase> filterProtocolTestCasesByTags(testCases: List<T>): List<T> =
        testCases.filter { testCase ->
            testCase.protocol == ctx.protocol && tagsToIgnore.none { tag -> testCase.hasTag(tag) }
        }
}

private fun serverOnly(shape: Shape): Boolean = shape.hasTag("server-only")

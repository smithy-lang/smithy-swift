/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */
package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.model.knowledge.OperationIndex
import software.amazon.smithy.model.knowledge.TopDownIndex
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.protocoltests.traits.HttpMessageTestCase
import software.amazon.smithy.protocoltests.traits.HttpRequestTestsTrait
import software.amazon.smithy.protocoltests.traits.HttpResponseTestsTrait
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.defaultName
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
    // list of test IDs to ignore/skip
    private val testsToIgnore: Set<String> = setOf()
) {
    private val LOGGER = Logger.getLogger(javaClass.name)

    /**
     * Generates the API HTTP protocol tests defined in the smithy model.
     */
    fun generateProtocolTests() {
        val operationIndex: OperationIndex = OperationIndex.of(ctx.model)
        val topDownIndex: TopDownIndex = TopDownIndex.of(ctx.model)
        val serviceSymbol = ctx.symbolProvider.toSymbol(ctx.service)

        for (operation in TreeSet(topDownIndex.getContainedOperations(ctx.service).filterNot(::serverOnly))) {

            // 1. Generate test cases for each request.
            operation.getTrait(HttpRequestTestsTrait::class.java)
                .ifPresent { trait: HttpRequestTestsTrait ->
                    val testCases = filterProtocolTestCases(trait.testCases)
                    if (testCases.isEmpty()) {
                        return@ifPresent
                    }

                    val testClassName = "${operation.id.name.capitalize()}RequestTest"
                    val testFilename = "./${ctx.settings.moduleName}Tests/$testClassName.swift"
                    ctx.delegator.useTestFileWriter(testFilename, ctx.settings.moduleName) { writer ->
                        LOGGER.fine("Generating request protocol test cases for ${operation.id}")
                        // import dependencies
                        writer.addImport(SwiftDependency.CLIENT_RUNTIME.namespace)
                        writer.addImport(ctx.settings.moduleName)
                        writer.addImport(SwiftDependency.SMITHY_TEST_UTIL.namespace)
                        writer.addImport(SwiftDependency.XCTest.namespace)

                        requestTestBuilder
                            .writer(writer)
                            .model(ctx.model)
                            .symbolProvider(ctx.symbolProvider)
                            .operation(operation)
                            .serviceName(serviceSymbol.name)
                            .testCases(testCases)
                            .build()
                            .renderTestClass(testClassName)
                    }
                }

            // 2. Generate test cases for each response.
            operation.getTrait(HttpResponseTestsTrait::class.java)
                .ifPresent { trait: HttpResponseTestsTrait ->
                    val testCases = filterProtocolTestCases(trait.testCases)
                    if (testCases.isEmpty()) {
                        return@ifPresent
                    }

                    val testClassName = "${operation.id.name.capitalize()}ResponseTest"
                    val testFilename = "./${ctx.settings.moduleName}Tests/$testClassName.swift"
                    ctx.delegator.useTestFileWriter(testFilename, ctx.settings.moduleName) { writer ->
                        LOGGER.fine("Generating response protocol test cases for ${operation.id}")
                        // import dependencies
                        writer.addImport(SwiftDependency.CLIENT_RUNTIME.namespace)
                        writer.addImport(ctx.settings.moduleName)
                        writer.addImport(SwiftDependency.SMITHY_TEST_UTIL.namespace)
                        writer.addImport(SwiftDependency.XCTest.namespace)

                        responseTestBuilder
                            .writer(writer)
                            .model(ctx.model)
                            .symbolProvider(ctx.symbolProvider)
                            .operation(operation)
                            .serviceName(serviceSymbol.name)
                            .testCases(testCases)
                            .build()
                            .renderTestClass(testClassName)
                    }
                }

            // 3. Generate test cases for each error on each operation.
            for (error in operationIndex.getErrors(operation).filterNot(::serverOnly)) {
                error.getTrait(HttpResponseTestsTrait::class.java)
                    .ifPresent { trait: HttpResponseTestsTrait ->
                        val testCases = filterProtocolTestCases(trait.testCases)
                        if (testCases.isEmpty()) {
                            return@ifPresent
                        }
                        // multiple error (tests) may be associated with a single operation,
                        // use the operation name + error name as the class name
                        val opName = operation.id.name.capitalize()
                        val testClassName = "${opName}${error.defaultName()}Test"
                        val testFilename = "./${ctx.settings.moduleName}Tests/${opName}ErrorTest.swift"
                        ctx.delegator.useTestFileWriter(testFilename, ctx.settings.moduleName) { writer ->
                            LOGGER.fine("Generating error protocol test cases for ${operation.id}")
                            // import dependencies
                            writer.addImport(SwiftDependency.CLIENT_RUNTIME.namespace)
                            writer.addImport(ctx.settings.moduleName)
                            writer.addImport(SwiftDependency.SMITHY_TEST_UTIL.namespace)
                            writer.addImport(SwiftDependency.XCTest.namespace)

                            errorTestBuilder
                                .error(error)
                                .writer(writer)
                                .model(ctx.model)
                                .symbolProvider(ctx.symbolProvider)
                                .operation(operation)
                                .serviceName(serviceSymbol.name)
                                .testCases(testCases)
                                .build()
                                .renderTestClass(testClassName)
                        }
                    }
            }
        }
    }

    private fun <T : HttpMessageTestCase> filterProtocolTestCases(testCases: List<T>): List<T> = testCases.filter {
        it.protocol == ctx.protocol && it.id !in testsToIgnore
    }
}

private fun serverOnly(shape: Shape): Boolean = shape.hasTag("server-only")

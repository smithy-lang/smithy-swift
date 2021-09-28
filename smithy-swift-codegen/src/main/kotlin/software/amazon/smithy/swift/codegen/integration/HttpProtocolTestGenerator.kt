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
import software.amazon.smithy.swift.codegen.getOrNull
import software.amazon.smithy.swift.codegen.integration.middlewares.RequestTestEndpointResolverMiddleware
import software.amazon.smithy.swift.codegen.middleware.MiddlewareStep
import software.amazon.smithy.swift.codegen.middleware.OperationMiddleware
import software.amazon.smithy.swift.codegen.model.capitalizedName
import software.amazon.smithy.swift.codegen.model.hasTrait
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
    private val operationMiddleware: OperationMiddleware,
    private val serdeContext: HttpProtocolUnitTestGenerator.SerdeContext,
    // list of test IDs to ignore/skip
    private val testsToIgnore: Set<String> = setOf()
) {
    private val LOGGER = Logger.getLogger(javaClass.name)

    /**
     * Generates the API HTTP protocol tests defined in the smithy model.
     */
    fun generateProtocolTests(): Int {
        val topDownIndex: TopDownIndex = TopDownIndex.of(ctx.model)
        val serviceSymbol = ctx.symbolProvider.toSymbol(ctx.service)
        val operationMiddleware = updateRequestTestMiddleware()
        var numTests = 0
        for (operation in TreeSet(topDownIndex.getContainedOperations(ctx.service).filterNot(::serverOnly))) {
            numTests += renderRequestTests(operation, serviceSymbol, operationMiddleware)
            numTests += renderResponseTests(operation, serviceSymbol)
            numTests += renderErrorTestCases(operation, serviceSymbol)
        }
        return numTests
    }

    private fun updateRequestTestMiddleware(): OperationMiddleware {
        val topDownIndex: TopDownIndex = TopDownIndex.of(ctx.model)
        val requestTestOperations = TreeSet(topDownIndex.getContainedOperations(ctx.service)
            .filter { it.hasTrait<HttpRequestTestsTrait>() }
            .filterNot(::serverOnly))
        val cloned = operationMiddleware.clone()

        for (operation in requestTestOperations) {
            cloned.removeMiddleware(operation, MiddlewareStep.BUILDSTEP, "EndpointResolverMiddleware")
            cloned.removeMiddleware(operation, MiddlewareStep.BUILDSTEP, "UserAgentMiddleware")
            cloned.removeMiddleware(operation, MiddlewareStep.FINALIZESTEP, "RetryMiddleware")
            cloned.removeMiddleware(operation, MiddlewareStep.FINALIZESTEP, "AWSSigningMiddleware") // causes tests to halt :(
            cloned.removeMiddleware(operation, MiddlewareStep.DESERIALIZESTEP, "DeserializeMiddleware")
            cloned.removeMiddleware(operation, MiddlewareStep.DESERIALIZESTEP, "LoggingMiddleware")

            cloned.appendMiddleware(operation, RequestTestEndpointResolverMiddleware(ctx.model, ctx.symbolProvider))
        }
        return cloned
    }

    private fun renderRequestTests(operation: OperationShape, serviceSymbol: Symbol, operationMiddleware: OperationMiddleware): Int {
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
                    .operationMiddleware(operationMiddleware)
                    .serdeContext(serdeContext)
                    .build()
                    .renderTestClass(testClassName)
            }
        }
        return requestTestCases.count()
    }

    private fun renderResponseTests(operation: OperationShape, serviceSymbol: Symbol): Int {
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
                    .operationMiddleware(operationMiddleware)
                    .serdeContext(serdeContext)
                    .build()
                    .renderTestClass(testClassName)
            }
        }
        return responseTestCases.count()
    }

    private fun renderErrorTestCases(operation: OperationShape, serviceSymbol: Symbol): Int {
        val operationIndex: OperationIndex = OperationIndex.of(ctx.model)
        var numTestCases = 0
        for (error in operationIndex.getErrors(operation).filterNot(::serverOnly)) {
            val tempTestCases = error.getTrait(HttpResponseTestsTrait::class.java)
                .getOrNull()
                ?.getTestCasesFor(AppliesTo.CLIENT)
                .orEmpty()
            val testCases = filterProtocolTestCases(tempTestCases)
            numTestCases += testCases.count()
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
                        .operationMiddleware(operationMiddleware)
                        .serdeContext(serdeContext)
                        .build()
                        .renderTestClass(testClassName)
                }
            }
        }
        return numTestCases
    }

    private fun <T : HttpMessageTestCase> filterProtocolTestCases(testCases: List<T>): List<T> = testCases.filter {
        it.protocol == ctx.protocol && it.id !in testsToIgnore
    }
}

private fun serverOnly(shape: Shape): Boolean = shape.hasTag("server-only")

package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.model.node.ObjectNode
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.smoketests.traits.SmokeTestCase
import software.amazon.smithy.smoketests.traits.SmokeTestsTrait
import software.amazon.smithy.swift.codegen.ShapeValueGenerator
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.model.expectTrait
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.utils.toLowerCamelCase
import software.amazon.smithy.swift.codegen.utils.toUpperCamelCase

open class SmokeTestGenerator(
    private val ctx: ProtocolGenerator.GenerationContext
) {
    fun generateSmokeTests() {
        val serviceName = getServiceName()
        val operationShapeIdToTestCases = getOperationShapeIdToTestCasesMapping()
        val testCaseNames = operationShapeIdToTestCases.values.flatten().map { it.id.toLowerCamelCase() }
        ctx.delegator.useFileWriter("SmokeTests/${serviceName}SmokeTestRunner/${serviceName}SmokeTestRunner.swift") { writer ->
            renderPrefixContent(serviceName, writer)
            renderMainFunction(testCaseNames, serviceName, writer)
            renderTestFunctions(operationShapeIdToTestCases, serviceName, writer)
            // Main function call at the end of the file for executable entry-point.
            writer.write("await main()")
        }
    }

    /**
     * Override this method for vendor-specific & customized service names.
     */
    open fun getServiceName(): String {
        return ctx.settings.sdkId.toUpperCamelCase()
    }

    private fun getOperationShapeIdToTestCasesMapping(): Map<ShapeId, List<SmokeTestCase>> {
        val operationShapeIdToTestCases = mutableMapOf<ShapeId, List<SmokeTestCase>>()
        ctx.service.allOperations.forEach { op ->
            if (ctx.model.expectShape(op).hasTrait<SmokeTestsTrait>()) {
                val testCases = mutableListOf<SmokeTestCase>()
                val smokeTestTrait = ctx.model.expectShape(op).expectTrait<SmokeTestsTrait>()
                smokeTestTrait.testCases.forEach { testCase ->
                    testCases.add(testCase)
                }
                operationShapeIdToTestCases[op] = testCases
            }
        }
        return operationShapeIdToTestCases
    }

    /**
     * Override this method for vendor-specific behavior.
     * Writes fileprivate Swift variables / constants at file level, to be used by test functions.
     * E.g., values from environment variable(s).
     */
    open fun renderCustomFilePrivateVariables(writer: SwiftWriter) {
        // Default behavior: no test tags are skipped.
        writer.write("fileprivate let tagsToSkip = []")
    }

    // Render content before main and test functions.
    private fun renderPrefixContent(serviceName: String, writer: SwiftWriter) {
        // Import statements
        writer.write("import Foundation")
        writer.write("import $serviceName")
        // Render fileprivate variables
        renderCustomFilePrivateVariables(writer)
    }

    private fun renderMainFunction(testCaseNames: List<String>, serviceName: String, writer: SwiftWriter) {
        writer.openBlock("func main() async {", "}") {
            // Print diagnostic line & test plan line.
            writer.write("print(\$S)", "# $serviceName Smoke Tests")
            writer.write("print(\$S", "1..${testCaseNames.size}")
            // Call all test functions.
            writer.write("var allTestsPassed = true")
            testCaseNames.forEach {
                writer.write("allTestsPassed = allTestsPassed && (await $it())")
            }
            // Exit with 0 or 1 based on allTestsPassed boolean.
            renderExitBlock(writer)
        }
    }

    //    if allTestsPassed {
    //        exit(0)
    //    } else {
    //        exit(1)
    //    }
    private fun renderExitBlock(writer: SwiftWriter) {
        writer.write("if allTestsPassed {")
        writer.indent()
        writer.write("exit(0)")
        writer.dedent()
        writer.write("} else {")
        writer.indent()
        writer.write("exit(1)")
        writer.dedent()
        writer.write("}")
    }

    private fun renderTestFunctions(operationShapeIdToTestCases: Map<ShapeId, List<SmokeTestCase>>, serviceName: String, writer: SwiftWriter) {
        operationShapeIdToTestCases.forEach { mapping ->
            val operationShapeId = mapping.key
            mapping.value.forEach { testCase ->
                renderTestFunction(operationShapeId, testCase, serviceName, writer)
            }
        }
    }

    private fun renderTestFunction(operationShapeId: ShapeId, testCase: SmokeTestCase, serviceName: String, writer: SwiftWriter) {
        val testCaseName = testCase.id.toLowerCamelCase()
        writer.openBlock(
            "func $testCaseName() async -> Bool {",
            "}"
        ) {
            val commaSeparatedTags = testCase.tags.joinToString(", ") { "\"$it\"" }
            writer.write("let tagsFromTrait = [$commaSeparatedTags]")
            // If the test has a tag we need to skip, runtime code needs to output skipped success line and return true.
            writer.openBlock("if !Set(tagsToSkip).isDisjoint(with: tagsFromTrait) {", "}") {
                renderPrintTestResult(writer, true, serviceName, operationShapeId.name, testCase.expectation.isFailure, true)
            }
            // Print diagnostic line with test name.
            writer.write("print(\$S)", "# Running test: $testCaseName")
            // Construct input, client, and run test; output result accordingly.
            renderDoCatchBlock(operationShapeId, testCase, serviceName, writer)
        }
    }

    private fun renderPrintTestResult(
        writer: SwiftWriter,
        isSuccess: Boolean,
        serviceName: String,
        operationName: String,
        errorExpected: Boolean,
        isSkipped: Boolean = false,
        printStacktrace: Boolean = false
    ) {
        val result = if (isSuccess) "ok" else "not ok"
        val error = if (errorExpected) "error expected from service" else "no error expected from service"
        val skipped = if (isSkipped) " # skip" else ""
        writer.write("print(\$S)", "$result $serviceName $operationName - $error$skipped")
        if (printStacktrace) {
            writer.write("Thread.callStackSymbols.forEach { print(\"# \" + $0) }")
        }
        writer.write("return $result")
    }

    private fun renderDoCatchBlock(operationShapeId: ShapeId, testCase: SmokeTestCase, serviceName: String, writer: SwiftWriter) {
        val operationName = operationShapeId.name
        val errorExpected = testCase.expectation.isFailure
        val specificErrorExpected = errorExpected && testCase.expectation.failure.get().errorId.isPresent

        writer.write("do {")
        writer.indent()
        // Construct input struct with params from trait.
        val inputShape = ctx.model.expectShape(ctx.model.expectShape(operationShapeId).asOperationShape().get().inputShape)
        writer.writeInline("\nlet input = ")
            .call {
                ShapeValueGenerator(ctx.model, ctx.symbolProvider).writeShapeValueInline(writer, inputShape, testCase.params.orElse(ObjectNode.builder().build()))
            }
            .write("")
        // Create empty config
        val clientName = getClientName()
        writer.write("let config = try await $clientName.${clientName}Configuration()")
        // Set any vendor-specific values into config.
        handleVendorParams(testCase.vendorParams.orElse(null), writer)
        // Construct client with the config
        writer.write("let client = $clientName(config: config)")
        // Call the operation with client and input
        writer.write("try await $clientName.${operationName.toLowerCamelCase()}(input: ${operationName}Input)")
        // Writer after client call:
        if (errorExpected) {
            // If error was expected, print failure line and return false.
            renderPrintTestResult(writer, false, serviceName, operationName, true)
        } else {
            // If expected success, print success line and return true.
            renderPrintTestResult(writer, true, serviceName, operationName, false)
        }
        writer.dedent()

        // Catch specific error only if it is expected
        if (specificErrorExpected) {
            val expectedErrorName = testCase.expectation.failure.get().errorId.get().name
            renderSpecificErrorCatchBlock(expectedErrorName, operationName, serviceName, writer)
        }

        // Catch generic error
        writer.write("} catch {")
        writer.indent()
        if (specificErrorExpected) {
            // Specific error was expected but some other error got caught; print failure, stacktrace of the error and return false.
            renderPrintTestResult(writer, false, serviceName, operationName, true, printStacktrace = true)
        } else if (errorExpected) {
            // If generic error was expected, print success and return true.
            renderPrintTestResult(writer, true, serviceName, operationName, true)
        } else {
            // If expected success, print failure, stacktrace of error, and return false.
            renderPrintTestResult(writer, false, serviceName, operationName, false, printStacktrace = true)
        }
        writer.dedent()
        writer.write("}")
    }

    open fun getClientName(): String {
        return ctx.settings.sdkId.toUpperCamelCase() + "Client"
    }

    /**
     * Default behavior is no-op; override this method for vendor-specific behavior.
     * Implementation should set config fields using values from vendorParams or custom fileprivate variables.
     */
    open fun handleVendorParams(vendorParams: ObjectNode, writer: SwiftWriter) {
        // Pseudo-code example:
        //      writer.write("config.value1 = ${value1-extracted-from-vendorParams}")
    }

    private fun renderSpecificErrorCatchBlock(expectedErrorName: String, operationName: String, serviceName: String, writer: SwiftWriter) {
        writer.write("} catch let error as $expectedErrorName {")
        writer.indent()
        // Since a specific error was expected and caught by this point, print success and return true
        renderPrintTestResult(writer, true, serviceName, operationName, true)
        writer.dedent()
    }
}

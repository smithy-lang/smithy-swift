package software.amazon.smithy.swift.codegen.integration

import software.amazon.smithy.model.node.ObjectNode
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.smoketests.traits.SmokeTestCase
import software.amazon.smithy.smoketests.traits.SmokeTestsTrait
import software.amazon.smithy.swift.codegen.ShapeValueGenerator
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.model.expectTrait
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.swiftmodules.FoundationTypes
import software.amazon.smithy.swift.codegen.utils.toLowerCamelCase
import software.amazon.smithy.swift.codegen.utils.toUpperCamelCase

open class SmokeTestGenerator(
    private val ctx: ProtocolGenerator.GenerationContext
) {
    // Filter out tests by name or tag at codegen time.
    // Each element must have the prefix "<service-name>:" before the test name or tag name.
    // E.g., "ServiceX:ProcessOrderTest" or "ServiceX:Order"
    open val testIdsToIgnore = setOf<String>()
    open val testTagsToIgnore = setOf<String>()

    fun generateSmokeTests() {
        val serviceName = getServiceName()
        val testRunnerName = serviceName + "SmokeTestRunner"
        val operationShapeIdToTestCases = getOperationShapeIdToTestCasesMapping(serviceName)
        val testCaseNames = operationShapeIdToTestCases.values.flatten().map { it.id.toLowerCamelCase() }
        if (testCaseNames.isNotEmpty()) {
            ctx.delegator.useFileWriter("SmokeTests/$testRunnerName/$testRunnerName.swift") { writer ->
                renderPrefixContent(serviceName, writer)
                addEmptyLine(writer)
                writer.write("@main")
                writer.openBlock("struct $testRunnerName {", "}") {
                    renderMainFunction(testCaseNames, serviceName, writer)
                    renderTestFunctions(operationShapeIdToTestCases, serviceName, writer)
                }
            }
        }
    }

    /**
     * Override this method for vendor-specific & customized service names.
     */
    open fun getServiceName(): String {
        return ctx.settings.sdkId.toUpperCamelCase()
    }

    /**
     * Returns map of operation shape IDs to smoke test cases to generate for that operation.
     * Ignores test cases by name or tag, using `testIdsToIgnore` and `testTagsToIgnore` constants.
     */
    private fun getOperationShapeIdToTestCasesMapping(serviceName: String): Map<ShapeId, List<SmokeTestCase>> {
        val operationShapeIdToTestCases = mutableMapOf<ShapeId, List<SmokeTestCase>>()
        ctx.service.allOperations.forEach { op ->
            if (ctx.model.expectShape(op).hasTrait<SmokeTestsTrait>()) {
                val testCases = mutableListOf<SmokeTestCase>()
                val smokeTestTrait = ctx.model.expectShape(op).expectTrait<SmokeTestsTrait>()
                smokeTestTrait.testCases.forEach { testCase ->
                    // Add test case only if neither its name nor tags is included in ignore lists.
                    val nameIsNotInIgnoreList = !testIdsToIgnore.contains("$serviceName:${testCase.id}")
                    val tagIsNotInIgnoreList = !testCase.tags.any { "$serviceName:$it" in testTagsToIgnore }
                    if (nameIsNotInIgnoreList && tagIsNotInIgnoreList) {
                        testCases.add(testCase)
                    }
                }
                // By this point, it's possible testCases is empty due to all tests being ignored.
                // Map to operation shape ID only if it's non-empty.
                if (testCases.isNotEmpty()) {
                    operationShapeIdToTestCases[op] = testCases
                }
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
        writer.addImport(FoundationTypes.ProcessInfo)
        writer.addImport(ClientRuntimeTypes.Core.SDKLoggingSystem)
        writer.addImport(serviceName)
        // Render fileprivate variables
        renderCustomFilePrivateVariables(writer)
    }

    private fun renderMainFunction(testCaseNames: List<String>, serviceName: String, writer: SwiftWriter) {
        writer.openBlock("static func main() async {", "}") {
            // Silence trivial non-test logs
            writer.write("await SDKLoggingSystem().initialize(logLevel: .error)")
            // Print diagnostic line & test plan line.
            writer.write("print(\$S)", "# Running $serviceName Smoke Tests...")
            writer.write("print(\$S)", "1..${testCaseNames.size}")
            // Call all test functions.
            writer.write("var allTestsPassed = true")
            testCaseNames.forEach {
                writer.write("allTestsPassed = await $it() && allTestsPassed")
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
                addEmptyLine(writer)
                renderTestFunction(operationShapeId, testCase, serviceName, writer)
            }
        }
    }

    private fun renderTestFunction(operationShapeId: ShapeId, testCase: SmokeTestCase, serviceName: String, writer: SwiftWriter) {
        writer.openBlock(
            "static func ${testCase.id.toLowerCamelCase()}() async -> Bool {",
            "}"
        ) {
            val commaSeparatedTags = testCase.tags.joinToString(", ") { "\"$it\"" }
            writer.write("let tagsFromTrait: [String] = [$commaSeparatedTags]")
            // If the test has a tag we need to skip, runtime code needs to output skipped success line and return true.
            writer.openBlock("if !Set(tagsToSkip).isDisjoint(with: tagsFromTrait) {", "}") {
                renderPrintTestResult(writer, true, serviceName, operationShapeId.name, testCase.expectation.isFailure, true)
            }
            // Print diagnostic line with test name.
            writer.write("print(\$S)", "# Running test case: [${testCase.id}]...")
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
        printCaughtError: Boolean = false
    ) {
        val result = if (isSuccess) "ok" else "not ok"
        val error = if (errorExpected) "error expected from service" else "no error expected from service"
        val skipped = if (isSkipped) " # skip" else ""
        writer.write("print(\$S)", "$result $serviceName $operationName - $error$skipped")
        if (printCaughtError) {
            writer.write("print(\"# Caught unexpected error: \\(error)\")")
        }
        writer.write("return $isSuccess")
    }

    private fun renderDoCatchBlock(operationShapeId: ShapeId, testCase: SmokeTestCase, serviceName: String, writer: SwiftWriter) {
        val operationName = operationShapeId.name
        val errorExpected = testCase.expectation.isFailure
        val specificErrorExpected = errorExpected && testCase.expectation.failure.get().errorId.isPresent

        writer.write("do {")
        writer.indent()
        // Construct input struct with params from trait.
        val inputShape = ctx.model.expectShape(ctx.model.expectShape(operationShapeId).asOperationShape().get().inputShape)
        if (testCase.params?.get()?.size() == 0) {
            writer.write("let input = ${inputShape.id.name}()")
        } else {
            writer.writeInline("let input = ")
                .call {
                    ShapeValueGenerator(ctx.model, ctx.symbolProvider).writeShapeValueInline(
                        writer,
                        inputShape,
                        testCase.params.orElse(ObjectNode.builder().build())
                    )
                }
                .write("")
        }
        // Create empty config
        val clientName = getClientName()
        writer.write("let config = try await $clientName.${clientName}Configuration()")
        // Set any vendor-specific values into config.
        handleVendorParams(testCase.vendorParams.orElse(null), writer)
        // Construct client with the config
        writer.write("let client = $clientName(config: config)")
        // Call the operation with client and input
        writer.write("_ = try await client.${operationName.toLowerCamelCase()}(input: input)")
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
            // Specific error was expected but some other error got caught; print failure & the unexpected error and return false.
            renderPrintTestResult(writer, false, serviceName, operationName, true, printCaughtError = true)
        } else if (errorExpected) {
            // If generic error was expected, print success and return true.
            renderPrintTestResult(writer, true, serviceName, operationName, true)
        } else {
            // If expected success, print failure, the unexpected error, and return false.
            renderPrintTestResult(writer, false, serviceName, operationName, false, printCaughtError = true)
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

    private fun addEmptyLine(writer: SwiftWriter) {
        writer.write("")
    }
}

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.waiters

import software.amazon.smithy.jmespath.JmespathExpression
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.core.CodegenContext
import software.amazon.smithy.swift.codegen.utils.toLowerCamelCase
import software.amazon.smithy.waiters.Acceptor
import software.amazon.smithy.waiters.Matcher
import software.amazon.smithy.waiters.PathComparator
import software.amazon.smithy.waiters.PathMatcher

// Renders the initializer for one Smithy waiter acceptor into Swift,
// using the provided writer & shapes.
// The Acceptor is defined in Smithy here:
// https://smithy.io/2.0/additional-specs/waiters.html#acceptor-structure
class WaiterAcceptorGenerator(
    val writer: SwiftWriter,
    val ctx: CodegenContext,
    val service: ServiceShape,
    val waitedOperation: OperationShape,
    val acceptor: Acceptor,
) {

    fun render() {
        writer.openBlock(
            ".init(state: .\$L, matcher: { (input: \$L, result: Result<\$L, Error>) -> Bool in", "}),",
            acceptor.state,
            inputTypeName,
            outputTypeName
        ) {
            val matcher = acceptor.matcher
            // There are 4 possible types of acceptor.  Render each separately below.
            when (matcher) {
                is Matcher.SuccessMember -> {
                    writer.openBlock("switch result {", "}") {
                        writer.write("case .success: return \$L", "true".takeIf { matcher.value } ?: "false")
                        writer.write("case .failure: return \$L", "false".takeIf { matcher.value } ?: "true")
                    }
                }
                is Matcher.OutputMember -> {
                    renderInputOutputBlockContents(false, matcher.value)
                }
                is Matcher.InputOutputMember -> {
                    renderInputOutputBlockContents(true, matcher.value)
                }
                is Matcher.ErrorTypeMember -> {
                    val errorType = matcher.value.toLowerCamelCase()
                    writer.write("guard case .failure(let error) = result else { return false }")
                    writer.write("return (error as? WaiterTypedError)?.waiterErrorType == \$S", errorType)
                }
            }
        }
    }

    private fun renderInputOutputBlockContents(includeInput: Boolean, pathMatcher: PathMatcher) {
        writer.write("// JMESPath expression: ${pathMatcher.path}")
        writer.write("// JMESPath comparator: ${pathMatcher.comparator}")
        writer.write("// JMESPath expected value: ${pathMatcher.expected}")
        writer.write("guard case .success(let unwrappedOutput) = result else { return false }")
        // output and inputOutput type acceptors are the same except that:
        // - An output waiter has the output object at its root scope
        // - An inputOutput waiter has an object with the properties input and output at its root scope
        // Depending on the type of waiter, current is set to establish that scope.
        if (includeInput) {
            writer.write(
                "let current = Optional.some(WaiterConfiguration<\$L, \$L>.Acceptor.InputOutput(input: input, output: unwrappedOutput))",
                inputTypeName,
                outputTypeName
            )
        } else {
            writer.write("let current = Optional.some(unwrappedOutput)")
        }

        // Use smithy to parse the text JMESPath expression into a syntax tree to be visited.
        val expression = JmespathExpression.parse(pathMatcher.path)

        // Create a visitor & send it through the tree.  actual will hold the name of the variable
        // with the result of the expression
        val visitor = JMESPathVisitor(writer)
        val actual = expression.accept(visitor)

        // Get the expected result and type of comparison needed, and render the result.
        val expected = pathMatcher.expected
        when (pathMatcher.comparator) {
            PathComparator.STRING_EQUALS ->
                writer.write("return JMESValue(\$L) == JMESValue(\$S)", actual, expected)
            PathComparator.BOOLEAN_EQUALS ->
                writer.write("return JMESValue(\$L) == JMESValue(\$L)", actual, expected.toBoolean())
            PathComparator.ANY_STRING_EQUALS ->
                writer.write("return \$L?.contains(where: { JMESValue($$0) == JMESValue(\$S) }) ?? false", actual, expected)
            PathComparator.ALL_STRING_EQUALS ->
                writer.write("return (\$L?.count ?? 0) > 1 && (\$L?.allSatisfy { JMESValue($$0) == JMESValue(\$S) } ?? false)", actual, actual, expected)
        }
    }

    private val inputTypeName: String = waitedOperation.inputShape.name

    private val outputTypeName: String = waitedOperation.outputShape.name
}

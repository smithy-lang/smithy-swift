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
// import software.amazon.smithy.swift.codegen.model.toUpperCamelCase
import software.amazon.smithy.swift.codegen.utils.toLowerCamelCase
import software.amazon.smithy.waiters.Acceptor
import software.amazon.smithy.waiters.Matcher
import software.amazon.smithy.waiters.PathComparator
import software.amazon.smithy.waiters.PathMatcher

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
//                    val errorTypeName = "${waitedOperation.toUpperCamelCase()}OutputError"
                    writer.write("// Match on error case: \$L", matcher.value.toLowerCamelCase())
                    writer.write("return false")
//                    writer.openBlock("switch result {", "}") {
//                        writer.write("case .failure(let error as \$L):", errorTypeName)
//                        writer.indent()
//                        writer.write("if case .\$L = error { return true } else { return false }", errorEnumCaseName)
//                        writer.dedent()
//                        writer.write("default: return false")
//                    }
                }
            }
        }
    }

    private fun renderInputOutputBlockContents(includeInput: Boolean, pathMatcher: PathMatcher) {
        writer.write("// JMESPath expression: ${pathMatcher.path}")
        writer.write("// JMESPath comparator: ${pathMatcher.comparator}")
        writer.write("// JMESPath expected value: ${pathMatcher.expected}")
        writer.write("guard case .success(let unwrappedOutput) = result else { return false }")
        if (includeInput) {
            writer.write(
                "let current = Optional.some(WaiterConfiguration<\$L, \$L>.Acceptor.InputOutput(input: input, output: unwrappedOutput))",
                inputTypeName,
                outputTypeName
            )
        } else {
            writer.write("let current = Optional.some(unwrappedOutput)")
        }
        val visitor = JMESPathVisitor(writer)
        val expression = JmespathExpression.parse(pathMatcher.path)
        val actual = expression.accept(visitor)

        val expected = pathMatcher.expected
        when (pathMatcher.comparator) {
            PathComparator.STRING_EQUALS ->
                writer.write("return JMESValue(\$L) == JMESValue(\"\$L\")", actual, expected)
            PathComparator.BOOLEAN_EQUALS ->
                writer.write("return JMESValue(\$L) == JMESValue(\$L)", actual, expected.toBoolean())
            PathComparator.ANY_STRING_EQUALS ->
                writer.write("return \$L?.contains(where: { JMESValue($$0) == JMESValue(\"\$L\") }) ?? false", actual, expected)
            PathComparator.ALL_STRING_EQUALS ->
                writer.write("return (\$L?.count ?? 0) > 1 && (\$L?.allSatisfy { JMESValue($$0) == JMESValue(\"\$L\") } ?? false)", actual, actual, expected)
        }
    }

    private val inputTypeName: String = waitedOperation.inputShape.name

    private val outputTypeName: String = waitedOperation.outputShape.name
}

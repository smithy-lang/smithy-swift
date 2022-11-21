package software.amazon.smithy.swift.codegen.waiters

import software.amazon.smithy.jmespath.JmespathExpression
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.core.CodegenContext
import software.amazon.smithy.swift.codegen.model.toUpperCamelCase
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
        val inputType = waitedOperation.inputShape.name
        val outputType = waitedOperation.outputShape.name
        writer.openBlock(".init(state: .${acceptor.state.toString()}) { (input: $inputType, result: Result<$outputType, Error>) -> Bool in", "},") {
            val matcher = acceptor.matcher
            when (matcher) {
                is Matcher.SuccessMember -> {
                    writer.openBlock("switch result {", "}") {
                        writer.write("case .success: return ${"true".takeIf { matcher.value } ?: "false"}")
                        writer.write("case .failure: return ${"false".takeIf { matcher.value } ?: "true"}")
                    }
                }
                is Matcher.OutputMember -> {
                    renderInputOutputBlockContents(false, matcher.value)
                }
                is Matcher.InputOutputMember -> {
                    renderInputOutputBlockContents(true, matcher.value)
                }
                is Matcher.ErrorTypeMember -> {
                    val errorTypeName = "${waitedOperation.toUpperCamelCase()}OutputError"
                    var errorEnumCaseName = "${matcher.value.toLowerCamelCase()}"
                    writer.openBlock("switch result {", "}") {
                        writer.write("case .failure(let error as \$L):", errorTypeName)
                        writer.indent()
                        writer.write("if case .\$L = error { return true } else { return false }", errorEnumCaseName)
                        writer.dedent()
                        writer.write("default: return false")
                    }
                }
            }
        }
    }

    private fun renderInputOutputBlockContents(includeInput: Boolean, pathMatcher: PathMatcher) {
        writer.write("guard case .success(let output) = result else { return false }")
        if (includeInput) {
            writer.write("let root = InputOutput(input: input, output: output)")
        } else {
            writer.write("let root = Optional.some(output)")
        }
        val visitor = JMESPathVisitor(writer)
        val expression = JmespathExpression.parse(pathMatcher.path)
        val actual = expression.accept(visitor)

        val expected = pathMatcher.expected
        val comparison = when (pathMatcher.comparator) {
            PathComparator.STRING_EQUALS -> "return \"\\($actual ?? \"nil\")\" == \"\\(${expected} ?? \"nil\")\""
            PathComparator.BOOLEAN_EQUALS -> "return $actual == ${expected.toBoolean()}"
            PathComparator.ANY_STRING_EQUALS -> "return $actual?.contains { \"\\($$0 ?? \"nil\")\" == \"${expected}\" } ?? false"
            PathComparator.ALL_STRING_EQUALS ->
                "return ($actual?.count ?? 0) > 1 && ($actual?.allSatisfy { \"\\($$0 ?? \"nil\")\" == \"${expected}\" } ?? false)"
        }
        writer.write(comparison)
    }
}

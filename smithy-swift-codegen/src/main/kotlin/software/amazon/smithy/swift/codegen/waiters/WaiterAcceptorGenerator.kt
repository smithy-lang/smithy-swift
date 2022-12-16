/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.waiters

import software.amazon.smithy.jmespath.JmespathExpression
import software.amazon.smithy.model.shapes.BooleanShape
import software.amazon.smithy.model.shapes.DoubleShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.StringShape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.SymbolVisitor
import software.amazon.smithy.swift.codegen.core.CodegenContext
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
                    writer.write("guard case .failure(let error) = result else { return false }")
                    writer.write("return (error as? WaiterTypedError)?.waiterErrorType == \$S", matcher.value)
                }
            }
        }
    }

    private fun renderInputOutputBlockContents(includeInput: Boolean, pathMatcher: PathMatcher) {
        writer.write("// JMESPath expression: \"${pathMatcher.path}\"")
        writer.write("// JMESPath comparator: \"${pathMatcher.comparator}\"")
        writer.write("// JMESPath expected value: \"${pathMatcher.expected}\"")
        val startingVar: Variable
        // output and inputOutput type acceptors are the same except that:
        // - An output waiter has the output object at its root scope
        // - An inputOutput waiter has an object with the properties input and output at its root scope
        // Depending on the type of waiter, starting var is set to establish that scope.
        if (includeInput) {
            writer.write("guard case .success(let unwrappedOutput) = result else { return false }")
            writer.write(
                "let inputOutput = WaiterConfiguration<\$L, \$L>.Acceptor.InputOutput(input: input, output: unwrappedOutput)",
                inputTypeName,
                outputTypeName
            )
            startingVar = Variable("inputOutput", false, inputOutputShape)
        } else {
            writer.write("guard case .success(let output) = result else { return false }")
            startingVar = Variable("output", false, ctx.model.expectShape(waitedOperation.outputShape))
        }

        // Use smithy to parse the text JMESPath expression into a syntax tree to be visited.
        val expression = JmespathExpression.parse(pathMatcher.path)

        // Create a model & symbol provider with the JMESPath synthetic types included in it
        val model = ctx.model.toBuilder()
            .addShapes(listOf(inputOutputShape, boolShape, stringShape, doubleShape))
            .build()
        val symbolProvider = SymbolVisitor(model, ctx.settings)

        // Create a visitor & send it through the AST.  actual will hold the name of the variable
        // with the result of the expression
        val visitor = JMESPathVisitor(writer, startingVar, model, symbolProvider)
        val actual = expression.accept(visitor)

        // Get the expected result and type of comparison needed, and render the result.
        val expected = pathMatcher.expected
        when (pathMatcher.comparator) {
            PathComparator.STRING_EQUALS ->
                writer.write("return JMESUtils.test(\$L, ==, \$S)", actual.name, expected)
            PathComparator.BOOLEAN_EQUALS ->
                writer.write("return JMESUtils.test(\$L, ==, \$L)", actual.name, expected.toBoolean())
            PathComparator.ANY_STRING_EQUALS ->
                writer.write(
                    "return \$L?.contains(where: { JMESUtils.test($$0, ==, \$S) }) ?? false",
                    actual.name,
                    expected
                )
            PathComparator.ALL_STRING_EQUALS ->
                writer.write(
                    "return (\$L?.count ?? 0) > 1 && (\$L?.allSatisfy { JMESUtils.test($$0, ==, \$S) } ?? false)",
                    actual.name,
                    actual.name,
                    expected
                )
        }
    }

    // Types used for acceptor input & output

    private val inputTypeName: String =
        ctx.symbolProvider.toSymbol(ctx.model.expectShape(waitedOperation.inputShape)).name

    private val outputTypeName: String =
        ctx.symbolProvider.toSymbol(ctx.model.expectShape(waitedOperation.outputShape)).name

    // Shapes used within JMESPath expressions

    private val stringShape = StringShape.builder().id("smithy.swift.synthetic#LiteralString").build()

    private val boolShape = BooleanShape.builder().id("smithy.swift.synthetic#LiteralBoolean").build()

    private val doubleShape = DoubleShape.builder().id("smithy.swift.synthetic#LiteralDouble").build()

    val inputOutputShape: Shape
        get() {
            val inputMember = MemberShape.builder()
                .id("smithy.swift.synthetic#InputOutput\$input")
                .target(waitedOperation.inputShape)
                .build()
            val outputMember = MemberShape.builder()
                .id("smithy.swift.synthetic#InputOutput\$output")
                .target(waitedOperation.outputShape)
                .build()
            return StructureShape.builder()
                .id("smithy.swift.synthetic#InputOutput")
                .members(
                    mutableListOf(inputMember, outputMember)
                )
                .build()
        }
}

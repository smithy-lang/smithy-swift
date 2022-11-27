/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.waiters

import software.amazon.smithy.jmespath.ExpressionVisitor
import software.amazon.smithy.jmespath.JmespathExpression
import software.amazon.smithy.jmespath.RuntimeType
import software.amazon.smithy.jmespath.ast.AndExpression
import software.amazon.smithy.jmespath.ast.ComparatorExpression
import software.amazon.smithy.jmespath.ast.CurrentExpression
import software.amazon.smithy.jmespath.ast.ExpressionTypeExpression
import software.amazon.smithy.jmespath.ast.FieldExpression
import software.amazon.smithy.jmespath.ast.FilterProjectionExpression
import software.amazon.smithy.jmespath.ast.FlattenExpression
import software.amazon.smithy.jmespath.ast.FunctionExpression
import software.amazon.smithy.jmespath.ast.IndexExpression
import software.amazon.smithy.jmespath.ast.LiteralExpression
import software.amazon.smithy.jmespath.ast.MultiSelectHashExpression
import software.amazon.smithy.jmespath.ast.MultiSelectListExpression
import software.amazon.smithy.jmespath.ast.NotExpression
import software.amazon.smithy.jmespath.ast.ObjectProjectionExpression
import software.amazon.smithy.jmespath.ast.OrExpression
import software.amazon.smithy.jmespath.ast.ProjectionExpression
import software.amazon.smithy.jmespath.ast.SliceExpression
import software.amazon.smithy.jmespath.ast.Subexpression
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.utils.toLowerCamelCase

private val suffixSequence = sequenceOf("") + generateSequence(2) { it + 1 }.map(Int::toString) // "", "2", "3", etc.

class JMESPathVisitor(val writer: SwiftWriter) : ExpressionVisitor<String> {
    private val tempVars = mutableSetOf<String>()

    private fun addTempVar(preferredName: String, codegen: String): String {
        val name = bestTempVarName(preferredName)
        writer.write("let \$L = \$L", name, codegen)
        return name
    }

    private fun bestTempVarName(preferredName: String): String =
        suffixSequence.map { "$preferredName$it" }.first(tempVars::add)

    private fun childBlock(forExpression: JmespathExpression): String =
        forExpression.accept(JMESPathVisitor(writer))

    private fun codegenReq(condition: Boolean, lazyMessage: () -> String) {
        if (!condition) throw Exception(lazyMessage())
    }

    private fun flatMappingBlock(right: JmespathExpression, leftName: String): String {
        if (right is CurrentExpression) return leftName // Nothing to map
        val outerName = bestTempVarName("projection")
        writer.openBlock("let \$LMapped = (\$L ?? []).flattenIfPossible { root in", "}", outerName, leftName) {
            writer.write("let root = Optional.some(root)")
            val innerResult = addTempVar("innerResult", childBlock(right))
            val innerCollector = when (right) {
                is MultiSelectListExpression -> "return $innerResult" // Already a list
                else -> "return [$innerResult].compactMap { $$0 }.flattenIfPossible { $$0 }"
            }
            writer.write(innerCollector)
        }
        writer.write("let \$L = Optional.some(\$LMapped.flattenIfPossible { $$0 })", outerName, outerName)
        return outerName
    }

    private fun subfield(expression: FieldExpression, parentName: String): String {
        val name = expression.name.toLowerCamelCase()
        return addTempVar(name, "$parentName?.$name")
    }

    override fun visitAnd(expression: AndExpression): String {
        writer.write("// visitAnd")
        val leftExp = expression.left!!.accept(this)
        val rightExp = expression.right!!.accept(this)
        return "($leftExp && $rightExp)"
    }

    override fun visitComparator(expression: ComparatorExpression): String {
        writer.write("// visitComparator")
        val left = expression.left!!.accept(this)
        val right = expression.right!!.accept(this)
        return addTempVar("comparison", "JMESValue($left) ${expression.comparator} JMESValue($right)")
    }

    override fun visitCurrentNode(expression: CurrentExpression): String {
        throw Exception("Unexpected current expression outside of flatten expression: $expression")
    }

    override fun visitExpressionType(expression: ExpressionTypeExpression): String {
        throw Exception("ExpressionTypeExpression is unsupported")
    }

    override fun visitField(expression: FieldExpression): String {
        writer.write("// visitField")
        return subfield(expression, "root")
    }

    override fun visitFilterProjection(expression: FilterProjectionExpression): String {
        writer.write("// visitFilterProjection")
        val leftName = expression.left!!.accept(this)
        val filteredName = bestTempVarName("${leftName}Filtered")

        writer.openBlock("let \$L = Optional.some((\$L ?? []).filter { root in", filteredName, leftName)
        writer.write("let root = Optional.some(root)")
        val comparisonName = childBlock(expression.comparison!!)
        writer.write("return \$L", comparisonName)

        writer.closeBlock("})")

        val right = expression.right!!
        return flatMappingBlock(right, filteredName)
    }

    override fun visitFlatten(expression: FlattenExpression): String {
        writer.write("// visitFlatten")
        val innerName = expression.expression!!.accept(this)
        return addTempVar("${innerName}OrEmpty", "Optional.some($innerName ?? [])?.flattenIfPossible { $0 }")
    }

    override fun visitFunction(expression: FunctionExpression): String {
        writer.write("// visitFunction")
        when (expression.name) {
            "contains" -> {
                codegenReq(expression.arguments.size == 2) { "Unexpected number of arguments to $expression" }

                val subject = expression.arguments[0]
                val subjectName = subject.accept(this)

                val search = expression.arguments[1]
                val searchName = search.accept(this)

                return addTempVar("contains", "$searchName.flatMap { $subjectName?.contains($0) } ?? false")
            }

            "length" -> {
                codegenReq(expression.arguments.size == 1) { "Unexpected number of arguments to $expression" }

                val subject = expression.arguments[0]
                val subjectName = subject.accept(this)

                return addTempVar("count", "Optional.some(Double($subjectName?.count ?? 0))")
            }

            else -> throw Exception("Unknown function type in $expression")
        }
    }

    override fun visitIndex(expression: IndexExpression): String {
        throw Exception("IndexExpression is unsupported")
    }

    override fun visitLiteral(expression: LiteralExpression): String {
        writer.write("// visitLiteral")
        when (expression.type) {
            RuntimeType.STRING -> return addTempVar("string", "Optional.some(\"" + expression.expectStringValue() + "\")")
            RuntimeType.NUMBER -> return addTempVar("number", "Optional.some(Double(${expression.expectNumberValue()}))")
            RuntimeType.BOOLEAN -> return addTempVar("bool", "Optional.some(${expression.expectBooleanValue()})")
            RuntimeType.NULL -> return "nil"
            else -> throw Exception("Expression type $expression is unsupported")
        }
    }

    override fun visitMultiSelectHash(expression: MultiSelectHashExpression): String {
        throw Exception("MultiSelectHashExpression is unsupported")
    }

    override fun visitMultiSelectList(expression: MultiSelectListExpression): String {
        writer.write("// visitMultiSelectList")
        val listName = bestTempVarName("multiSelect")
        val multiSelectVars = expression.expressions.map { inner ->
            return addTempVar("multiSelectValue", inner.accept(this))
        }
        writer.openBlock("let \$L = Optional.some([", "])", listName) {
            writer.write(multiSelectVars.joinToString { ",\n" })
        }
        return listName
    }

    override fun visitNot(expression: NotExpression): String {
        writer.write("// visitNot")
        val exp = expression.expression!!.accept(this)
        return "!$exp"
    }

    override fun visitObjectProjection(expression: ObjectProjectionExpression): String {
        writer.write("// visitObjectProjection")
        val leftName = expression.left!!.accept(this)
        val valuesName = addTempVar("${leftName}Values", "Optional.some(Array(($leftName ?? [:]).values))")
        return flatMappingBlock(expression.right!!, valuesName)
    }

    override fun visitOr(expression: OrExpression): String {
        throw Exception("OrExpression is unsupported")
    }

    override fun visitProjection(expression: ProjectionExpression): String {
        writer.write("// visitProjection")
        val leftName = expression.left!!.accept(this)
        return flatMappingBlock(expression.right!!, leftName)
    }

    override fun visitSlice(expression: SliceExpression): String {
        throw Exception("SliceExpression is unsupported")
    }

    override fun visitSubexpression(expression: Subexpression): String {
        writer.write("// visitSubexpression")
        val leftName = expression.left!!.accept(this)

        return when (val right = expression.right!!) {
            is FieldExpression -> subfield(right, leftName)
            else -> throw Exception("Subexpression type $right is unsupported")
        }
    }
}

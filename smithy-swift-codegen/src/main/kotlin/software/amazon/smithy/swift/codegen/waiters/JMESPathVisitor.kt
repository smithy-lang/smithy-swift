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

// sequence of "", "2", "3", "4", etc.
private val suffixSequence = sequenceOf("") + generateSequence(2) { it + 1 }.map(Int::toString)

// Visits the JMESPath syntax tree, rendering the JMESPath expression into a Swift expression.
// Smithy does not support all JMESPath expressions, and smithy-swift does not support all Smithy
// expressions.  However, this support is sufficient to generate all waiters currently in use on AWS.
// Use of a JMESPath feature not supported by Smithy will cause an exception at the time of code
// generation.

// Because JMESPath has no concept of non-optional, every visitor below will take an optional value
// as input and also return an optional.
class JMESPathVisitor(val writer: SwiftWriter) : ExpressionVisitor<String> {

    // A few methods are provided here for generating unique yet still somewhat
    // descriptive variable names when needed.
    private val tempVars = mutableSetOf<String>()

    private fun addTempVar(preferredName: String, content: String, vararg args: Any): String {
        val name = uniqueTempVarName(preferredName)
        writer.writeInline("let \$L = ", name)
        writer.write(content, *args)
        return name
    }

    // Returns a name, based on preferredName, that is guaranteed to be unique among those issued
    // by this visitor.
    // If not yet used, preferredName will be returned as the new variable name.  If preferredName
    // is not available, preferredname2, preferredname3, etc. will be used.
    // The chosen name is inserted into tempVars so it is not reused in a future call to this method.
    private fun uniqueTempVarName(preferredName: String): String =
        suffixSequence.map { "$preferredName$it" }.first(tempVars::add)

    // Some JMESPath expressions may have their own valid JMESPath expressions
    // within them, i.e. to map or filter.  This method is called to render
    // those expressions.
    private fun childBlock(forExpression: JmespathExpression): String =
        forExpression.accept(JMESPathVisitor(writer))

    // Maps the expression result in leftName into a new collection using the right expression.
    private fun mappingBlock(right: JmespathExpression, leftName: String): String {
        if (right is CurrentExpression) return leftName // Nothing to map
        val outerName = uniqueTempVarName("projection")
        writer.openBlock(
            "let \$L = Optional.some((\$L ?? []).compactMap { current in", "})",
            outerName,
            leftName
        ) {
            writer.write("let current = Optional.some(current)")
            val innerResult = addTempVar("innerResult", childBlock(right))
            writer.write("return \$L", innerResult)
        }
        return outerName
    }

    // Accesses a field on the expression named parentName & returns the name of the
    // resulting expression.
    private fun subfield(expression: FieldExpression, parentName: String): String {
        val name = expression.name.toLowerCamelCase()
        return addTempVar(name, "\$L?.\$L", parentName, name)
    }

    // Performs a Boolean "and" of the left & right expressions
    // A Swift compile error will result if both left & right aren't Bool.
    override fun visitAnd(expression: AndExpression): String {
        val leftExp = expression.left!!.accept(this)
        val rightExp = expression.right!!.accept(this)
        return addTempVar("andResult", "\$L && \$L", leftExp, rightExp)
    }

    // Perform a comparison of two values.
    // The JMESValue type is used to provide conversion and comparison as needed between types
    // that aren't comparable in "pure Swift" (i.e. Int to Double or String to RawRepresentable
    // by String.)
    // The Smithy comparator is a string that just happens to match up with all Swift comparators,
    // so it is rendered into Swift as-is.
    override fun visitComparator(expression: ComparatorExpression): String {
        val left = expression.left!!.accept(this)
        val right = expression.right!!.accept(this)
        return addTempVar("comparison", "JMESValue(\$L) \$L JMESValue(\$L)", left, expression.comparator, right)
    }

    override fun visitCurrentNode(expression: CurrentExpression): String {
        throw Exception("Unexpected current expression outside of flatten expression: $expression")
    }

    override fun visitExpressionType(expression: ExpressionTypeExpression): String {
        throw Exception("ExpressionTypeExpression is unsupported")
    }

    override fun visitField(expression: FieldExpression): String {
        return subfield(expression, "current")
    }

    // Filters elements from a collection which don't passing a test provided in a JMESPath child expression.
    override fun visitFilterProjection(expression: FilterProjectionExpression): String {
        val leftName = expression.left!!.accept(this)
        val filteredName = uniqueTempVarName("${leftName}Filtered")
        writer.openBlock("let \$L = Optional.some((\$L ?? []).filter { current in", "})", filteredName, leftName) {
            writer.write("let current = Optional.some(current)")
            val comparisonName = childBlock(expression.comparison!!)
            writer.write("return \$L", comparisonName)
        }
        val right = expression.right!!
        return mappingBlock(right, filteredName)
    }

    // Returns the inner expression unchanged when the inner expression is an array of non-array elements.
    // Returns the inner expression flattened when the inner expression is an array of arrays.
    override fun visitFlatten(expression: FlattenExpression): String {
        val innerName = expression.expression!!.accept(this)
        return addTempVar("${innerName}OrEmpty", "Optional.some((\$L ?? []).flattenIfPossible { $$0 })", innerName)
    }

    // Implement contains() and length() free functions which are the only 2 JMESPath methods we support.
    // contains() returns true if its 1st param is a collection that contains an element equal
    // to the 2nd param, false otherwise.
    // length() returns the number of elements of an array, the number of key/value pairs for a map,
    // or the number of characters for a string.
    override fun visitFunction(expression: FunctionExpression): String {
        when (expression.name) {
            "contains" -> {
                if (expression.arguments.size != 2) { throw Exception("Unexpected number of arguments to $expression") }

                val subject = expression.arguments[0]
                val subjectName = subject.accept(this)
                val search = expression.arguments[1]
                val searchName = search.accept(this)
                return addTempVar("contains", "\$L.flatMap { \$L?.contains($$0) } ?? false", searchName, subjectName)
            }
            "length" -> {
                if (expression.arguments.size != 1) { throw Exception("Unexpected number of arguments to $expression") }

                val subject = expression.arguments[0]
                val subjectName = subject.accept(this)
                return addTempVar("count", "Optional.some(Double(\$L?.count ?? 0))", subjectName)
            }
            else -> throw Exception("Unknown function type in $expression")
        }
    }

    override fun visitIndex(expression: IndexExpression): String {
        throw Exception("IndexExpression is unsupported")
    }

    // Renders a literal of any supported type, wrapped in an optional.
    override fun visitLiteral(expression: LiteralExpression): String {
        when (expression.type) {
            RuntimeType.STRING -> return addTempVar("string", "Optional.some(\$S)", expression.expectStringValue())
            RuntimeType.NUMBER -> return addTempVar("number", "Optional.some(Double(\$L))", expression.expectNumberValue())
            RuntimeType.BOOLEAN -> return addTempVar("bool", "Optional.some(\$L)", expression.expectBooleanValue())
            RuntimeType.NULL -> return "nil"
            else -> throw Exception("Expression type $expression is unsupported")
        }
    }

    override fun visitMultiSelectHash(expression: MultiSelectHashExpression): String {
        throw Exception("MultiSelectHashExpression is unsupported")
    }

    // Render a JMESPath multi-select to an array.
    // All expressions must result in the same type or a Swift compile error will occur.
    override fun visitMultiSelectList(expression: MultiSelectListExpression): String {
        val listName = uniqueTempVarName("multiSelect")
        val multiSelectVars = expression.expressions.map { inner ->
            return addTempVar("multiSelectValue", inner.accept(this))
        }
        writer.openBlock("let \$L = Optional.some([", "])", listName) {
            writer.write(multiSelectVars.joinToString { ",\n" })
        }
        return listName
    }

    // Negates the passed expression.
    // The passed expression must be Boolean, else a Swift compile error will occur.
    override fun visitNot(expression: NotExpression): String {
        val exp = expression.expression!!.accept(this)
        return "!$exp"
    }

    // Converts a JSON object / Swift dictionary into an array of its values.
    override fun visitObjectProjection(expression: ObjectProjectionExpression): String {
        val leftName = expression.left!!.accept(this)
        val valuesName = addTempVar("${leftName}Values", "Optional.some(Array((\$L ?? [:]).values))", leftName)
        return mappingBlock(expression.right!!, valuesName)
    }

    override fun visitOr(expression: OrExpression): String {
        throw Exception("OrExpression is unsupported")
    }

    // Maps a collection into a collection of a different type.
    override fun visitProjection(expression: ProjectionExpression): String {
        val leftName = expression.left!!.accept(this)
        return mappingBlock(expression.right!!, leftName)
    }

    override fun visitSlice(expression: SliceExpression): String {
        throw Exception("SliceExpression is unsupported")
    }

    // Returns a subexpression derived from a parent expression.
    // Only accessing fields is supported.
    override fun visitSubexpression(expression: Subexpression): String {
        val leftName = expression.left!!.accept(this)

        return when (val right = expression.right!!) {
            is FieldExpression -> subfield(right, leftName)
            else -> throw Exception("Subexpression type $right is unsupported")
        }
    }
}

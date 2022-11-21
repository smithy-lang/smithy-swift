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

class JMESPathVisitor(val writer: SwiftWriter): ExpressionVisitor<String> {
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
        writer.openBlock("let \$L = Optional.some(\$L.flatMap { root in", outerName, leftName)
        writer.write("let root = Optional.some(root)")
        val innerResult = childBlock(right)
        val innerCollector = when (right) {
            is MultiSelectListExpression -> "return $innerResult" // Already a list
            else -> "return [$innerResult].compactMap { $$0 }"
        }
        writer.write(innerCollector)

        writer.closeBlock("})")
        return outerName
    }

    private fun subfield(expression: FieldExpression, parentName: String): String {
        val name = expression.name.toLowerCamelCase()
        return addTempVar(name, "$parentName?.$name")
    }

    override fun visitAnd(expression: AndExpression): String {
        val leftExp = expression.left!!.accept(this)
        val rightExp = expression.right!!.accept(this)
        return "($leftExp && $rightExp)"
    }

    override fun visitComparator(expression: ComparatorExpression): String {
        val left = expression.left!!
        val leftBaseName = left.accept(this)

        val right = expression.right
        val rightBaseName = right.accept(this)

        val leftIsString = (left as? LiteralExpression)?.isStringValue ?: false
        val rightIsString = (right as? LiteralExpression)?.isStringValue ?: false

        val leftName = if (rightIsString && !leftIsString) "\"\\($leftBaseName ?? \"nil\")\"" else leftBaseName
        val rightName = if (leftIsString && !rightIsString) "\"\\($rightBaseName ?? \"nil\")\"" else rightBaseName

        val codegen = "($leftBaseName == nil || $rightBaseName == nil) ? false : $leftName ${expression.comparator} $rightName"
        return addTempVar("comparison", codegen)
    }

    override fun visitCurrentNode(expression: CurrentExpression): String {
        throw Exception("Unexpected current expression outside of flatten expression: $expression")
    }

    override fun visitExpressionType(expression: ExpressionTypeExpression): String {
        throw Exception("ExpressionTypeExpression is unsupported")
    }

    override fun visitField(expression: FieldExpression): String = subfield(expression, "root")

    override fun visitFilterProjection(expression: FilterProjectionExpression): String {
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
        val innerName = expression.expression!!.accept(this)
        return addTempVar("${innerName}OrEmpty", "$innerName?.compactMap { $0 } ?? []")
    }

    override fun visitFunction(expression: FunctionExpression): String = when (expression.name) {
        "contains" -> {
            codegenReq(expression.arguments.size == 2) { "Unexpected number of arguments to $expression" }

            val subject = expression.arguments[0]
            val subjectName = subject.accept(this)

            val search = expression.arguments[1]
            val searchName = search.accept(this)

            addTempVar("contains", "$subjectName?.contains($searchName) ?: false")
        }

        "length" -> {
            codegenReq(expression.arguments.size == 1) { "Unexpected number of arguments to $expression" }

            val subject = expression.arguments[0]
            val subjectName = subject.accept(this)

            addTempVar("count", "Optional.some(Double($subjectName?.count ?? 0))")
        }

        else -> throw Exception("Unknown function type in $expression")
    }

    override fun visitIndex(expression: IndexExpression): String {
        throw Exception("IndexExpression is unsupported")
    }

    override fun visitLiteral(expression: LiteralExpression): String = when (expression.type) {
        RuntimeType.STRING -> addTempVar("string", "Optional.some(\"" + expression.expectStringValue() + "\")")
        RuntimeType.NUMBER -> addTempVar("number", "Optional.some(Double(${expression.expectNumberValue()}))")
        RuntimeType.BOOLEAN -> addTempVar("bool", "Optional.some(${expression.expectBooleanValue()})")
        RuntimeType.NULL -> "nil"
        else -> throw Exception("Expression type $expression is unsupported")
    }

    override fun visitMultiSelectHash(expression: MultiSelectHashExpression): String {
        throw Exception("MultiSelectHashExpression is unsupported")
    }

    override fun visitMultiSelectList(expression: MultiSelectListExpression): String {
        val listName = bestTempVarName("multiSelect")
        writer.openBlock("val \$L = [", listName)

        expression.expressions.forEach { inner ->
            val innerName = inner.accept(this)
            writer.write("\$L,", innerName)
        }

        writer.closeBlock("].compactMap { $$0 }")
        return listName
    }

    override fun visitNot(expression: NotExpression): String {
        val exp = expression.expression!!.accept(this)
        return "!$exp"
    }

    override fun visitObjectProjection(expression: ObjectProjectionExpression): String {
        val leftName = expression.left!!.accept(this)
        val valuesName = addTempVar("${leftName}Values", "Array(($leftName ?? [:]).values)")
        return flatMappingBlock(expression.right!!, valuesName)
    }

    override fun visitOr(expression: OrExpression): String {
        throw Exception("OrExpression is unsupported")
    }

    override fun visitProjection(expression: ProjectionExpression): String {
        val leftName = expression.left!!.accept(this)
        return flatMappingBlock(expression.right!!, leftName)
    }

    override fun visitSlice(expression: SliceExpression): String {
        throw Exception("SliceExpression is unsupported")
    }

    override fun visitSubexpression(expression: Subexpression): String {
        val leftName = expression.left!!.accept(this)

        return when (val right = expression.right!!) {
            is FieldExpression -> subfield(right, leftName)
            else -> throw Exception("Subexpression type $right is unsupported")
        }
    }
}
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
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.BooleanShape
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.DoubleShape
import software.amazon.smithy.model.shapes.ListShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.shapes.StringShape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.traits.RequiredTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.utils.toLowerCamelCase

// sequence of "", "2", "3", "4", etc.
private val suffixSequence = sequenceOf("") + generateSequence(2) { it + 1 }.map(Int::toString)

class Variable (
    val name: String,
    val isOptional: Boolean,
    val shape: Shape
) {

    companion object {
        fun from(name: String, shape: Shape, model: Model): Variable {
            val unmemberizedShape: Shape
            val isOptional: Boolean
            when (shape) {
                is MemberShape -> {
                    unmemberizedShape = model.expectShape(shape.target)
                    isOptional = !(shape.hasTrait<RequiredTrait>() || unmemberizedShape.hasTrait<RequiredTrait>())
                }
                else -> {
                    unmemberizedShape = shape
                    isOptional = !shape.hasTrait<RequiredTrait>()
                }
            }
            return Variable(name, isOptional, unmemberizedShape)
        }
    }
    init {
    }
}

// Visits the JMESPath syntax tree, rendering the JMESPath expression into a Swift expression.
// Smithy does not support all JMESPath expressions, and smithy-swift does not support all Smithy
// expressions.  However, this support is sufficient to generate all waiters currently in use on AWS.
// Use of a JMESPath feature not supported by Smithy will cause an exception at the time of code
// generation.

// Because JMESPath has no concept of non-optional, every visitor below will take an optional value
// as input and also return an optional.
class JMESPathVisitor(val writer: SwiftWriter, val currentExpression: Variable, val model: Model) : ExpressionVisitor<Variable> {

    // A few methods are provided here for generating unique yet still somewhat
    // descriptive variable names when needed.
    private val tempVars = mutableSetOf<String>()

    private fun addTempVar(variable: Variable, content: String, vararg args: Any): Variable {
        val name = uniqueTempVarName(variable.name)
        writer.writeInline("let \$L = ", name)
        writer.write(content, *args)
        return Variable(name, variable.isOptional, variable.shape)
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
    private fun childBlock(forExpression: JmespathExpression, currentExpression: Variable): Variable =
        forExpression.accept(JMESPathVisitor(writer, currentExpression, model))

    // Maps the expression result in leftName into a new collection using the right expression.
    private fun mappingBlock(right: JmespathExpression, left: Variable): Variable {
        when (right) {
            is CurrentExpression -> return left  // Nothing to map
        }
        when (left.shape) {
            is CollectionShape -> {
                val outerName = uniqueTempVarName("projection")
                var transformed = Variable("", false, boolShape)
                writer.openBlock(
                    "let \$L = \$L?.compactMap { original in", "}",
                    outerName,
                    left.name
                ) {
                    val original = Variable("original", false, expectShape(left.shape.member.target))
                    transformed = childBlock(right, original)
                    writer.write("return \$L", transformed.name)
                }
                val returnMember = MemberShape.builder().id("smithy.swift.synthetic#mappedCollection\$member").target(transformed.shape).build()
                val returnType = ListShape.builder().id("smithy.swift.synthetic#mappedCollection").member(returnMember).build()
                return Variable(outerName, left.isOptional, returnType)
            }
            else -> throw Exception("Mapping a non-collection shape: ${left.shape}")
        }
    }

    // Accesses a field on the expression named parentName & returns the name of the
    // resulting expression.
    private fun subfield(expression: FieldExpression, parentExpression: Variable): Variable {
        when (parentExpression.shape) {
            is StructureShape -> {
                val parentMembers = parentExpression.shape.members()
                val subfieldMember = parentMembers.first { it.memberName == expression.name }
                val subfieldShape = expectShape(subfieldMember.target)
                val fieldName = expression.name.toLowerCamelCase()
                val fieldOperator = "?.".takeIf { parentExpression.isOptional } ?: "."

                // Because all fields on Swift models are now optional, every subfield value will also be optional
                // Later we may have to replace this with logic to determine actual optionality
                // so,
                // val subfieldIsOptional = parentExpression.isOptional || subfieldMember.hasTrait<RequiredTrait>()
                // becomes:
                val subfieldIsOptional = true
                return addTempVar(Variable(fieldName, subfieldIsOptional, subfieldShape), "\$L\$L\$L", parentExpression.name, fieldOperator, fieldName)
            }
            else -> {
                throw Exception("Accessed subfield on parent: $parentExpression")
            }
        }
    }

    // Performs a Boolean "and" of the left & right expressions
    // A Swift compile error will result if both left & right aren't Bool.
    override fun visitAnd(expression: AndExpression): Variable {
        val leftExp = expression.left!!.accept(this)
        val rightExp = expression.right!!.accept(this)
        return addTempVar(Variable("andResult", false, boolShape), "\$L && \$L", leftExp, rightExp)
    }

    // Perform a comparison of two values.
    // The JMESValue type is used to provide conversion and comparison as needed between types
    // that aren't comparable in "pure Swift" (i.e. Int to Double or String to RawRepresentable
    // by String.)
    // The Smithy comparator is a string that just happens to match up with all Swift comparators,
    // so it is rendered into Swift as-is.
    override fun visitComparator(expression: ComparatorExpression): Variable {
        val left = expression.left!!.accept(this)
        val right = expression.right!!.accept(this)
        return addTempVar(Variable("comparison", false, boolShape), "JMESValue(\$L) \$L JMESValue(\$L)", left.name, expression.comparator, right.name)
    }

    override fun visitCurrentNode(expression: CurrentExpression): Variable {
        throw Exception("Unexpected current expression outside of flatten expression: $expression")
    }

    override fun visitExpressionType(expression: ExpressionTypeExpression): Variable {
        throw Exception("ExpressionTypeExpression is unsupported")
    }

    override fun visitField(expression: FieldExpression): Variable {
        return subfield(expression, currentExpression)
    }

    // Filters elements from a collection which don't passing a test provided in a JMESPath child expression.
    override fun visitFilterProjection(expression: FilterProjectionExpression): Variable {
        val unfiltered = expression.left!!.accept(this)
        when (unfiltered.shape) {
            is ListShape -> {
                val filteredName = uniqueTempVarName("${unfiltered.name}Filtered")
                val filteredVar = Variable(filteredName, unfiltered.isOptional, unfiltered.shape)
                val elementShape = expectShape(unfiltered.shape.member.target)
                writer.openBlock("let \$L = \$L?.filter { original in", "}", filteredName, unfiltered.name) {
                    val original = Variable("original", false, elementShape)
                    val comparison = childBlock(expression.comparison!!, original)
                    writer.write("return \$L", comparison.name)
                }
                val right = expression.right!!
                return mappingBlock(right, filteredVar)
            }
            else -> throw Exception("Cannot filter non-list type: ${unfiltered.shape}")
        }
    }

    // Returns the inner expression unchanged when the inner expression is an array of non-array elements.
    // Returns the inner expression flattened when the inner expression is an array of arrays.
    override fun visitFlatten(expression: FlattenExpression): Variable {
        val toBeFlattened = expression.expression!!.accept(this)
        when (toBeFlattened.shape) {
            is ListShape -> {
                val elementShape = expectShape(toBeFlattened.shape.member.target)
                return when (elementShape) {
                    is ListShape -> {
                        // Double-nested List.  Perform Swift flat mapping.
                        val dotOperator= "?.".takeIf { toBeFlattened.isOptional } ?: "."
                        val flattenedVar = Variable("flattened", toBeFlattened.isOptional, elementShape)
                        addTempVar(flattenedVar, "\$L\$LflatMap { $$0 }", toBeFlattened.name, dotOperator)
                    }
                    else -> {
                        // Single nested List.  Return original list unchanged.
                        toBeFlattened
                    }
                }
            }
            else -> {
                return toBeFlattened
//                val exception = Exception("Cannot flatten non-list type: ${toBeFlattened.shape}")
//                throw exception
            }
        }
    }

    // Implement contains() and length() free functions which are the only 2 JMESPath methods we support.
    // contains() returns true if its 1st param is a collection that contains an element equal
    // to the 2nd param, false otherwise.
    // length() returns the number of elements of an array, the number of key/value pairs for a map,
    // or the number of characters for a string.
    override fun visitFunction(expression: FunctionExpression): Variable {
        when (expression.name) {
            "contains" -> {
                if (expression.arguments.size != 2) { throw Exception("Unexpected number of arguments to $expression") }
                val subject = expression.arguments[0]
                val subjectVariable = subject.accept(this)
                val search = expression.arguments[1]
                val searchVariable = search.accept(this)
                val subjectDotOperator = "?.".takeIf { subjectVariable.isOptional } ?: "."
                val returnValueVar = Variable("contains", false, boolShape)
                return if (searchVariable.isOptional) {
                    addTempVar(returnValueVar, "\$L.flatMap { \$L\$Lcontains($$0) } ?? false", searchVariable.name, subjectVariable.name, subjectDotOperator)
                } else {
                    addTempVar(returnValueVar, "\$L\$Lcontains(\$L)", subjectVariable.name, subjectDotOperator, searchVariable.name)
                }
            }
            "length" -> {
                if (expression.arguments.size != 1) { throw Exception("Unexpected number of arguments to $expression") }
                val subjectExp = expression.arguments[0]
                val subject = subjectExp.accept(this)

                when (subject.shape) {
                    is StringShape, is ListShape, is MapShape -> {
                        val dotOperator = "?.".takeIf { subject.isOptional } ?: "."
                        return addTempVar(Variable("count", false, doubleShape), "Double(\$L\$Lcount ?? 0)", subject.name, dotOperator)
                    }
                    else -> throw Exception("length function called on unsupported type: ${currentExpression.shape}")
                }
            }
            else -> throw Exception("Unknown function type in $expression")
        }
    }

    override fun visitIndex(expression: IndexExpression): Variable {
        throw Exception("IndexExpression is unsupported")
    }

    // Renders a literal of any supported type, wrapped in an optional.
    override fun visitLiteral(expression: LiteralExpression): Variable {
        when (expression.type) {
            RuntimeType.STRING -> return addTempVar(Variable("string", false, stringShape), "\$S", expression.expectStringValue())
            RuntimeType.NUMBER -> return addTempVar(Variable("number", false, doubleShape), "Double(\$L)", expression.expectNumberValue())
            RuntimeType.BOOLEAN -> return addTempVar(Variable("bool", false, boolShape), "\$L", expression.expectBooleanValue())
            RuntimeType.NULL -> return Variable("nil", true, boolShape)
            else -> throw Exception("Expression type $expression is unsupported")
        }
    }

    override fun visitMultiSelectHash(expression: MultiSelectHashExpression): Variable {
        throw Exception("MultiSelectHashExpression is unsupported")
    }

    // Render a JMESPath multi-select to an array.
    // All expressions must result in the same type or a Swift compile error will occur.
    override fun visitMultiSelectList(expression: MultiSelectListExpression): Variable {
        val listName = uniqueTempVarName("multiSelect")
        var innerShape = currentExpression.shape
        val multiSelectVars = expression.expressions.map { inner ->
            val result = inner.accept(this)
            innerShape = result.shape
            return result
        }
        writer.openBlock("let \$L = [", "]", listName) {
            writer.write(multiSelectVars.joinToString { ",\n" })
        }
        val memberShape = MemberShape.builder().id("smithy.swift.synthetic#MultiSelectListElement").build()
        return Variable(listName, false, ListShape.builder().id("smithy.swift.synthetic#MultiSelectList").build())
    }

    // Negates the passed expression.
    // The passed expression must be Boolean, else a Swift compile error will occur.
    override fun visitNot(expression: NotExpression): Variable {
        val expressionToNegate = expression.expression!!.accept(this)
        return addTempVar(Variable("negated", false, expressionToNegate.shape), "!\$L", expressionToNegate.name)
    }

    // Converts a JSON object / Swift dictionary into an array of its values.
    override fun visitObjectProjection(expression: ObjectProjectionExpression): Variable {
        val original = expression.left!!.accept(this)
        when (original.shape) {
            is MapShape -> {
                val valueShape = expectShape(original.shape.value.target)
                val valuesName = addTempVar(Variable("projected", false, valueShape), "Optional.some(Array((\$L ?? [:]).values))", original.name)
                return mappingBlock(expression.right!!, valuesName)
            }
            else -> throw Exception("Cannot object-project a non-map type: ${original.shape}")
        }
    }

    override fun visitOr(expression: OrExpression): Variable {
        throw Exception("OrExpression is unsupported")
    }

    // Maps a collection into a collection of a different type.
    override fun visitProjection(expression: ProjectionExpression): Variable {
        val leftName = expression.left!!.accept(this)
        return mappingBlock(expression.right!!, leftName)
    }

    override fun visitSlice(expression: SliceExpression): Variable {
        throw Exception("SliceExpression is unsupported")
    }

    // Returns a subexpression derived from a parent expression.
    // Only accessing fields is supported.
    override fun visitSubexpression(expression: Subexpression): Variable {
        val leftName = expression.left!!.accept(this)

        return when (val right = expression.right!!) {
            is FieldExpression -> subfield(right, leftName)
            else -> throw Exception("Subexpression type $right is unsupported")
        }
    }

    private fun expectShape(shapeID: ShapeId): Shape {
        val foundSyntheticShape = listOf(stringShape, boolShape, doubleShape).firstOrNull { it.toShapeId() == shapeID }
        if (foundSyntheticShape != null) return foundSyntheticShape
        return model.expectShape(shapeID)
    }

    private val stringShape = StringShape.builder().id("smithy.swift.synthetic#LiteralString").build()

    private val boolShape = BooleanShape.builder().id("smithy.swift.synthetic#LiteralBoolean").build()

    private val doubleShape = DoubleShape.builder().id("smithy.swift.synthetic#LiteralDouble").build()
}

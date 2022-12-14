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
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.utils.toLowerCamelCase

// sequence of "", "2", "3", "4", etc, used for creating unique local vars
private val suffixSequence = sequenceOf("") + generateSequence(2) { it + 1 }.map(Int::toString)

// Holds the name of a variable defined in Swift, plus the optionality and the Smithy
// shape equivalent of its type.
class Variable(

    // The name of the Swift variable that this data is stored in.
    val name: String,

    // true if this variable is an optional, false otherwise.
    // Used to render correct Swift using this variable.
    val isOptional: Boolean,

    // The Smithy shape that is equivalent to this variable's Swift type.
    // (Note that this will never be a MemberShape, rather the member shape's targeted shape.)
    val shape: Shape
)

// Visits the JMESPath syntax tree, rendering the JMESPath expression into a Swift expression and returning a Variable
// holding the result of the Swift expression.
//
// Smithy does not support all JMESPath expressions, and smithy-swift does not support all Smithy
// expressions.  However, this support is sufficient to generate all waiters currently in use on AWS.
// Use of a JMESPath feature not supported by Smithy or smithy-swift will cause an exception at the
// time of code generation.
class JMESPathVisitor(
    val writer: SwiftWriter,
    val currentExpression: Variable,
    val model: Model
) : ExpressionVisitor<Variable> {

    // A few methods are provided here for generating unique yet still somewhat
    // descriptive variable names when needed.

    // Storage for variable names already used in this scope / expression.
    private val tempVars = mutableSetOf<String>()

    // Returns a name, based on preferredName, that is guaranteed to be unique among those issued
    // by this visitor.
    // If not yet used, preferredName will be returned as the new variable name.  If preferredName
    // is not available, preferredname2, preferredname3, etc. will be used.
    // The chosen name is inserted into tempVars so it is not reused in a future call to this method.
    private fun uniqueTempVarName(preferredName: String): String =
        suffixSequence.map { "$preferredName$it" }.first(tempVars::add)

    // Creates a temporary var with the type & optionality of the passed var, but with a name
    // based on the passed var but guaranteed to be unique.
    // The new temp var is set to the result of the passed expression.
    private fun addTempVar(variable: Variable, content: String, vararg args: Any): Variable {
        val tempVar = Variable(uniqueTempVarName(variable.name), variable.isOptional, variable.shape)
        writer.writeInline("let \$L = ", tempVar.name)
        writer.write(content, *args)
        return tempVar
    }

    // Some JMESPath expressions may have their own valid JMESPath expressions
    // within them, i.e. to map or filter.  This method is called to render
    // those expressions.
    private fun childBlock(forExpression: JmespathExpression, currentExpression: Variable): Variable =
        forExpression.accept(JMESPathVisitor(writer, currentExpression, model))

    // Maps the expression result in leftName into a new collection using the right expression.
    private fun mappingBlock(right: JmespathExpression, left: Variable): Variable {
        when (right) {
            is CurrentExpression -> return left // Nothing to map
        }
        when (left.shape) {
            is CollectionShape -> {
                val outerName = uniqueTempVarName("projection")
                // initialized as a mutable var with placeholder value since Kotlin doesn't like if the initial value
                // is set in the writer closure below
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
                val returnMember = MemberShape.builder()
                    .id("smithy.swift.synthetic#mappedCollection\$member")
                    .target(transformed.shape)
                    .build()
                val returnType = ListShape.builder()
                    .id("smithy.swift.synthetic#mappedCollection")
                    .member(returnMember)
                    .build()
                return Variable(outerName, left.isOptional, returnType)
            }
            else -> throw Exception("Mapping a non-collection shape: ${left.shape}")
        }
    }

    // Accesses a field on the parent variable & returns a variable containing the
    // resulting expression.
    private fun subfield(expression: FieldExpression, parentVar: Variable): Variable {
        when (parentVar.shape) {
            is StructureShape -> {
                val parentMembers = parentVar.shape.members()
                val subfieldMember = parentMembers.first { it.memberName == expression.name }
                val subfieldShape = expectShape(subfieldMember.target)
                val subfieldName = expression.name.toLowerCamelCase()
                val fieldOperator = "?.".takeIf { parentVar.isOptional } ?: "."
                //
                // Because all fields on Swift models are currently optional, every subfield value will also be
                // optional.  Later we may have to replace this with logic to determine actual optionality,
                // so:
                // val subfieldIsOptional = parentExpression.isOptional || subfieldMember.hasTrait<RequiredTrait>()
                // is replaced with:
                val subfieldIsOptional = true

                val subfieldVarName = uniqueTempVarName(subfieldName)
                val subfieldVar = Variable(subfieldVarName, subfieldIsOptional, subfieldShape)
                return addTempVar(subfieldVar, "\$L\$L\$L", parentVar.name, fieldOperator, subfieldName)
            }
            else -> {
                throw Exception("Accessed subfield on parent: $parentVar")
            }
        }
    }

    // Performs a Boolean "and" of the left & right expressions
    // A Swift compile error will result if both left & right aren't Booleans.
    override fun visitAnd(expression: AndExpression): Variable {
        val leftExp = expression.left!!.accept(this)
        val rightExp = expression.right!!.accept(this)
        val andResultVar = Variable("andResult", false, boolShape)
        return addTempVar(andResultVar, "\$L && \$L", leftExp, rightExp)
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
        val comparisonResultVar = Variable("comparison", false, boolShape)
        return addTempVar(
            comparisonResultVar,
            "JMESValue(\$L) \$L JMESValue(\$L)",
            left.name,
            expression.comparator,
            right.name
        )
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

    // Filters a collection to only those elements which pass a test provided in a JMESPath child expression.
    override fun visitFilterProjection(expression: FilterProjectionExpression): Variable {
        val unfiltered = expression.left!!.accept(this)
        when (unfiltered.shape) {
            is ListShape -> {
                val filteredName = uniqueTempVarName("${unfiltered.name}Filtered")
                val filteredVar = Variable(filteredName, unfiltered.isOptional, unfiltered.shape)
                val elementShape = expectShape(unfiltered.shape.member.target)
                writer.openBlock(
                    "let \$L = \$L?.filter { original in",
                    "}",
                    filteredName,
                    unfiltered.name
                ) {
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
        return when (toBeFlattened.shape) {
            is ListShape -> {
                val elementShape = expectShape(toBeFlattened.shape.member.target)
                when (elementShape) {
                    is ListShape -> {
                        // Double-nested List.  Perform Swift flat mapping.
                        val flattenedVar = Variable("flattened", toBeFlattened.isOptional, elementShape)
                        val dotOperator = "?.".takeIf { toBeFlattened.isOptional } ?: "."
                        addTempVar(flattenedVar, "\$L\$LflatMap { $$0 }", toBeFlattened.name, dotOperator)
                    }
                    else -> {
                        // Single nested List.  Return original list unchanged.
                        toBeFlattened
                    }
                }
            }
            else -> {
                toBeFlattened
            }
        }
    }

    // Implement contains() and length() free functions which are the only 2 JMESPath methods we support.
    // contains() returns true if its 1st param is a collection that contains an element equal
    // to the 2nd param, false otherwise.
    // length() returns the number of elements of an array, the number of key/value pairs for a map,
    // or the number of characters for a string.  Zero is returned if the argument is nil.
    override fun visitFunction(expression: FunctionExpression): Variable {
        when (expression.name) {
            "contains" -> {
                if (expression.arguments.size != 2) {
                    throw Exception("Unexpected number of arguments to $expression")
                }
                val subject = expression.arguments[0]
                val subjectVariable = subject.accept(this)
                val search = expression.arguments[1]
                val searchVariable = search.accept(this)
                val subjectDotOperator = "?.".takeIf { subjectVariable.isOptional } ?: "."
                val returnValueVar = Variable("contains", false, boolShape)
                return if (searchVariable.isOptional) {
                    addTempVar(
                        returnValueVar,
                        "\$L.flatMap { \$L\$Lcontains($$0) } ?? false",
                        searchVariable.name,
                        subjectVariable.name,
                        subjectDotOperator
                    )
                } else {
                    addTempVar(
                        returnValueVar,
                        "\$L\$Lcontains(\$L)",
                        subjectVariable.name,
                        subjectDotOperator,
                        searchVariable.name
                    )
                }
            }
            "length" -> {
                if (expression.arguments.size != 1) {
                    throw Exception("Unexpected number of arguments to $expression")
                }
                val subjectExp = expression.arguments[0]
                val subject = subjectExp.accept(this)

                return when (subject.shape) {
                    is StringShape, is ListShape, is MapShape -> {
                        val countVar = Variable("count", false, doubleShape)
                        val dotOperator = "?.".takeIf { subject.isOptional } ?: "."
                        addTempVar(countVar, "Double(\$L\$Lcount ?? 0)", subject.name, dotOperator)
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

    // Renders a literal of any supported type.
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
        val multiSelectListShape = ListShape.builder()
            .id("smithy.swift.synthetic#MultiSelectList")
            .member(memberShape)
            .build()
        return Variable(listName, false, multiSelectListShape)
    }

    // Negates the passed expression.
    // The passed expression must be Boolean, else a Swift compile error will occur.
    override fun visitNot(expression: NotExpression): Variable {
        val expressionToNegate = expression.expression!!.accept(this)
        val negatedVar = Variable("negated", false, expressionToNegate.shape)
        return addTempVar(negatedVar, "!\$L", expressionToNegate.name)
    }

    // Converts a JSON object / Swift dictionary into an array of its values.
    override fun visitObjectProjection(expression: ObjectProjectionExpression): Variable {
        val original = expression.left!!.accept(this)
        return when (original.shape) {
            is MapShape -> {
                val valueShape = expectShape(original.shape.value.target)
                val mapToProjectVar = Variable("mapToProject", false, valueShape)
                val valuesVar = addTempVar(mapToProjectVar, "Array((\$L ?? [:]).values))", original.name)
                mappingBlock(expression.right!!, valuesVar)
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

    // When looking up a shape by ID, check for a synthetic literal (defined below) before
    // checking the current model.
    private fun expectShape(shapeID: ShapeId): Shape {
        val foundSyntheticShape = listOf(stringShape, boolShape, doubleShape).firstOrNull { it.toShapeId() == shapeID }
        if (foundSyntheticShape != null) return foundSyntheticShape
        return model.expectShape(shapeID)
    }

    // Below are Smithy shapes to be used with JMESPath literals.

    private val stringShape = StringShape.builder().id("smithy.swift.synthetic#LiteralString").build()

    private val boolShape = BooleanShape.builder().id("smithy.swift.synthetic#LiteralBoolean").build()

    private val doubleShape = DoubleShape.builder().id("smithy.swift.synthetic#LiteralDouble").build()
}

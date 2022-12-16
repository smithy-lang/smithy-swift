/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.waiters

import software.amazon.smithy.codegen.core.SymbolProvider
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
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.ListShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.shapes.StringShape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.utils.BufferWriter

// sequence of "", "2", "3", "4", etc, used for creating unique local vars
private val suffixSequence = sequenceOf("") + generateSequence(2) { it + 1 }.map(Int::toString)

// Visits the JMESPath syntax tree, rendering the JMESPath expression into a Swift expression and returning a Variable
// holding the result of the Swift expression.
//
// Smithy does not support all JMESPath expressions, and smithy-swift does not support all Smithy
// expressions.  However, this support is sufficient to generate all waiters currently in use on AWS.
// Use of a JMESPath feature not supported by Smithy or smithy-swift will cause an exception at the
// time of code generation.
class JMESPathVisitor(
    val writer: SwiftWriter,
    val currentExpression: JMESVariable,
    val model: Model,
    val symbolProvider: SymbolProvider
) : ExpressionVisitor<JMESVariable> {

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
    private fun addTempVar(variable: JMESVariable, content: String, vararg args: Any): JMESVariable {
        val tempVar = JMESVariable(uniqueTempVarName(variable.name), variable.isOptional, variable.shape)
        writer.writeInline("let \$L = ", tempVar.name)
        writer.write(content, *args)
        return tempVar
    }

    // Some JMESPath expressions may have their own valid JMESPath expressions
    // within them, i.e. to map or filter.  This method is called to render
    // those expressions.
    private fun childBlock(forExpression: JmespathExpression, currentExpression: JMESVariable): JMESVariable =
        forExpression.accept(JMESPathVisitor(writer, currentExpression, model, symbolProvider))

    // Maps the expression result in leftName into a new collection using the right expression.
    private fun mappingBlock(right: JmespathExpression, left: JMESVariable): JMESVariable {
        when (right) {
            is CurrentExpression -> return left // Nothing to map
        }
        when (left.shape) {
            is CollectionShape -> {
                val outerName = uniqueTempVarName("projection")
                val original = JMESVariable("original", false, model.expectShape(left.shape.member.target))
                val bufferWriter = BufferWriter(writer)
                var transformedVar: JMESVariable? = null
                bufferWriter.record { writer ->
                    transformedVar = childBlock(right, original)
                }
                val optionalityMark = "?".takeIf { left.isOptional } ?: ""
                writer.openBlock(
                    "let \$L: [\$L]\$L = \$L\$L.compactMap { original in", "}",
                    outerName,
                    transformedVar!!.baseSwiftSymbol(symbolProvider),
                    optionalityMark,
                    left.name,
                    optionalityMark
                ) {
                    bufferWriter.playback()
                    writer.write("return \$L", transformedVar!!.name)
                }
                val returnMember = MemberShape.builder()
                    .id("smithy.swift.synthetic#mappedCollection\$member")
                    .target(transformedVar!!.shape)
                    .build()
                val returnType = ListShape.builder()
                    .id("smithy.swift.synthetic#mappedCollection")
                    .member(returnMember)
                    .build()
                return JMESVariable(outerName, left.isOptional, returnType)
            }
            else -> throw Exception("Mapping a non-collection shape: ${left.shape}")
        }
    }

    // Accesses a field on the parent variable & returns a variable containing the
    // resulting expression.
    private fun subfield(expression: FieldExpression, parentVar: JMESVariable): JMESVariable {
        when (parentVar.shape) {
            is StructureShape -> {
                val parentMembers = parentVar.shape.members()
                val subfieldMember = parentMembers.first { it.memberName == expression.name }
                val subfieldShape = model.expectShape(subfieldMember.target)
                val subfieldName = symbolProvider.toMemberName(subfieldMember)
                val fieldOperator = "?.".takeIf { parentVar.isOptional } ?: "."
                //
                // Because all fields on Swift models are currently optional, every subfield value will also be
                // optional.  Later we may have to replace this with logic to determine actual optionality,
                // so:
                // val subfieldIsOptional = !subfieldMember.hasTrait<RequiredTrait>()
                // is temporarily replaced with:
                val subfieldIsOptional = true

                val subfieldVar = JMESVariable(subfieldName, subfieldIsOptional, subfieldShape)
                return addTempVar(subfieldVar, "\$L\$L\$L", parentVar.name, fieldOperator, subfieldName)
            }
            else -> {
                throw Exception("Accessed subfield on parent: $parentVar")
            }
        }
    }

    // Performs a Boolean "and" of the left & right expressions
    // A Swift compile error will result if both left & right aren't Booleans.
    override fun visitAnd(expression: AndExpression): JMESVariable {
        val leftExp = expression.left!!.accept(this)
        val rightExp = expression.right!!.accept(this)
        val andResultVar = JMESVariable("andResult", false, boolShape)
        return addTempVar(andResultVar, "\$L && \$L", leftExp, rightExp)
    }

    // Perform a comparison of two values.
    // The JMESValue type is used to provide conversion and comparison as needed between types
    // that aren't comparable in "pure Swift" (i.e. Int to Double or String to RawRepresentable
    // by String.)
    // The Smithy comparator is a string that just happens to match up with all Swift comparators,
    // so it is rendered into Swift as-is.
    override fun visitComparator(expression: ComparatorExpression): JMESVariable {
        val left = expression.left!!.accept(this)
        val right = expression.right!!.accept(this)
        val comparisonResultVar = JMESVariable("comparison", false, boolShape)
        return addTempVar(
            comparisonResultVar,
            "JMESUtils.compare(\$L, \$L, \$L)",
            left.name,
            expression.comparator,
            right.name
        )
    }

    override fun visitCurrentNode(expression: CurrentExpression): JMESVariable {
        throw Exception("Unexpected current expression outside of flatten expression: $expression")
    }

    override fun visitExpressionType(expression: ExpressionTypeExpression): JMESVariable {
        throw Exception("ExpressionTypeExpression is unsupported")
    }

    override fun visitField(expression: FieldExpression): JMESVariable {
        return subfield(expression, currentExpression)
    }

    // Filters a collection to only those elements which pass a test provided in a JMESPath child expression.
    override fun visitFilterProjection(expression: FilterProjectionExpression): JMESVariable {
        val unfiltered = expression.left!!.accept(this)
        when (unfiltered.shape) {
            is ListShape -> {
                val elementShape = model.expectShape(unfiltered.shape.member.target)
                val bufferWriter = BufferWriter(writer)
                bufferWriter.record { writer ->
                    val original = JMESVariable("original", false, elementShape)
                    val predicateVar = childBlock(expression.comparison!!, original)
                    writer.write("return \$L", predicateVar.name)
                }
                val filteredName = uniqueTempVarName("${unfiltered.name}Filtered")
                val filteredVar = JMESVariable(filteredName, unfiltered.isOptional, unfiltered.shape)
                val optionalityMark = "?".takeIf { unfiltered.isOptional } ?: ""
                writer.openBlock(
                    "let \$L: \$L = \$L\$L.filter { original in",
                    "}",
                    filteredName,
                    unfiltered.swiftSymbolWithOptionality(symbolProvider),
                    unfiltered.name,
                    optionalityMark
                ) {
                    bufferWriter.playback()
                }
                val right = expression.right!!
                return mappingBlock(right, filteredVar)
            }
            else -> throw Exception("Cannot filter non-list type: ${unfiltered.shape}")
        }
    }

    // Returns the inner expression unchanged when the inner expression is an array of non-array elements.
    // Returns the inner expression flattened when the inner expression is an array of arrays.
    override fun visitFlatten(expression: FlattenExpression): JMESVariable {
        val toBeFlattened = expression.expression!!.accept(this)
        return when (toBeFlattened.shape) {
            is ListShape -> {
                val elementShape = model.expectShape(toBeFlattened.shape.member.target)
                when (elementShape) {
                    is ListShape -> {
                        // Double-nested List.  Perform Swift flat mapping.
                        val flattenedVar = JMESVariable("flattened", toBeFlattened.isOptional, elementShape)
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
    override fun visitFunction(expression: FunctionExpression): JMESVariable {
        when (expression.name) {
            "contains" -> {
                if (expression.arguments.size != 2) {
                    throw Exception("Unexpected number of arguments to $expression")
                }
                val subject = expression.arguments[0]
                val subjectVariable = subject.accept(this)
                val search = expression.arguments[1]
                val searchVariable = search.accept(this)
                val subjectOptionalityMark = "?".takeIf { subjectVariable.isOptional } ?: ""
                val returnValueVar = JMESVariable("contains", false, boolShape)
                return if (searchVariable.isOptional) {
                    addTempVar(
                        returnValueVar,
                        "\$L.flatMap { \$L\$L.contains($$0) } ?? false",
                        searchVariable.name,
                        subjectVariable.name,
                        subjectOptionalityMark
                    )
                } else {
                    val subjectNilCoalescence = " ?? false".takeIf { subjectVariable.isOptional } ?: ""
                    addTempVar(
                        returnValueVar,
                        "\$L\$L.contains(\$L)\$L",
                        subjectVariable.name,
                        subjectOptionalityMark,
                        searchVariable.name,
                        subjectNilCoalescence
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
                        val countVar = JMESVariable("count", false, doubleShape)
                        val optionalityMark = "?".takeIf { subject.isOptional } ?: ""
                        val nilCoalescense = " ?? 0".takeIf { subject.isOptional } ?: ""
                        addTempVar(
                            countVar,
                            "Double(\$L\$L.count\$L)",
                            subject.name,
                            optionalityMark,
                            nilCoalescense
                        )
                    }
                    else -> throw Exception("length function called on unsupported type: ${currentExpression.shape}")
                }
            }
            else -> throw Exception("Unknown function type in $expression")
        }
    }

    override fun visitIndex(expression: IndexExpression): JMESVariable {
        throw Exception("IndexExpression is unsupported")
    }

    // Renders a literal of any supported type.
    override fun visitLiteral(expression: LiteralExpression): JMESVariable {
        when (expression.type) {
            RuntimeType.STRING -> return addTempVar(JMESVariable("string", false, stringShape), "\$S", expression.expectStringValue())
            RuntimeType.NUMBER -> return addTempVar(JMESVariable("number", false, doubleShape), "Double(\$L)", expression.expectNumberValue())
            RuntimeType.BOOLEAN -> return addTempVar(JMESVariable("bool", false, boolShape), "\$L", expression.expectBooleanValue())
            RuntimeType.NULL -> return JMESVariable("nil", true, boolShape)
            else -> throw Exception("Expression type $expression is unsupported")
        }
    }

    override fun visitMultiSelectHash(expression: MultiSelectHashExpression): JMESVariable {
        throw Exception("MultiSelectHashExpression is unsupported")
    }

    // Render a JMESPath multi-select to an array.
    // All expressions must result in the same type or a Swift compile error will occur.
    override fun visitMultiSelectList(expression: MultiSelectListExpression): JMESVariable {
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
        return JMESVariable(listName, false, multiSelectListShape)
    }

    // Negates the passed expression.
    // The passed expression must be Boolean, else a Swift compile error will occur.
    override fun visitNot(expression: NotExpression): JMESVariable {
        val expressionToNegate = expression.expression!!.accept(this)
        val negatedVar = JMESVariable("negated", false, expressionToNegate.shape)
        return addTempVar(negatedVar, "!\$L", expressionToNegate.name)
    }

    // Converts a JSON object / Swift dictionary into an array of its values.
    override fun visitObjectProjection(expression: ObjectProjectionExpression): JMESVariable {
        val original = expression.left!!.accept(this)
        return when (original.shape) {
            is MapShape -> {
                val valueShape = model.expectShape(original.shape.value.target)
                val projectionShape = ListShape.builder()
                    .id("smithy.swift.synthetic#ObjectProjection")
                    .member(valueShape.toShapeId())
                    .build()
                var projectionVar = JMESVariable("projection", original.isOptional, projectionShape)
                if (original.isOptional) {
                    projectionVar = addTempVar(projectionVar, "\$L.map { Array($$0.values) }", original.name)
                } else {
                    projectionVar = addTempVar(projectionVar, "Array(\$L.values)", original.name)
                }
                mappingBlock(expression.right!!, projectionVar)
            }
            else -> throw Exception("Cannot object-project a non-map type: ${original.shape}")
        }
    }

    override fun visitOr(expression: OrExpression): JMESVariable {
        throw Exception("OrExpression is unsupported")
    }

    // Maps a collection into a collection of a different type.
    override fun visitProjection(expression: ProjectionExpression): JMESVariable {
        val leftName = expression.left!!.accept(this)
        return mappingBlock(expression.right!!, leftName)
    }

    override fun visitSlice(expression: SliceExpression): JMESVariable {
        throw Exception("SliceExpression is unsupported")
    }

    // Returns a subexpression derived from a parent expression.
    // Only accessing fields is supported.
    override fun visitSubexpression(expression: Subexpression): JMESVariable {
        val leftVar = expression.left!!.accept(this)

        return when (val right = expression.right!!) {
            is FieldExpression -> subfield(right, leftVar)
            else -> throw Exception("Subexpression type $right is unsupported")
        }
    }

    // Below are Smithy shapes to be used with JMESPath literals.

    private val stringShape =
        model.expectShape(ShapeId.from("smithy.swift.synthetic#LiteralString"))

    private val boolShape =
        model.expectShape(ShapeId.from("smithy.swift.synthetic#LiteralBoolean"))

    private val doubleShape =
        model.expectShape(ShapeId.from("smithy.swift.synthetic#LiteralDouble"))
}

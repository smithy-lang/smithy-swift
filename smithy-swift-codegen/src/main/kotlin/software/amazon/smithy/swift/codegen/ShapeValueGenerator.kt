/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */
package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.node.ArrayNode
import software.amazon.smithy.model.node.BooleanNode
import software.amazon.smithy.model.node.Node
import software.amazon.smithy.model.node.NodeVisitor
import software.amazon.smithy.model.node.NullNode
import software.amazon.smithy.model.node.NumberNode
import software.amazon.smithy.model.node.ObjectNode
import software.amazon.smithy.model.node.StringNode
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.DocumentShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.shapes.UnionShape
import software.amazon.smithy.model.traits.EnumTrait

/**
 * Generates a shape type declaration based on the parameters provided.
 */
class ShapeValueGenerator(
    internal val model: Model,
    internal val symbolProvider: SymbolProvider
) {

    /**
     * Writes generation of a shape value type declaration for the given the parameters.
     *
     * @param writer writer to write generated code with.
     * @param shape the shape that will be declared.
     * @param params parameters to fill the generated shape declaration.
     */
    fun writeShapeValueInline(writer: SwiftWriter, shape: Shape, params: Node, isRecursiveMember: Boolean = false) {
        val nodeVisitor = ShapeValueNodeVisitor(writer, this, shape)

        when (shape.type) {
            ShapeType.STRUCTURE -> structDecl(writer, shape.asStructureShape().get(), isRecursiveMember) {
                params.accept(nodeVisitor)
            }
            ShapeType.MAP -> mapDecl(writer, shape.asMapShape().get()) {
                params.accept(nodeVisitor)
            }
            ShapeType.LIST, ShapeType.SET -> collectionDecl(writer, shape as CollectionShape) {
                params.accept(nodeVisitor)
            }
            ShapeType.UNION -> unionDecl(writer, shape.asUnionShape().get()) {
                params.accept(nodeVisitor)
            }
            else -> primitiveDecl(writer, shape) {
                params.accept(nodeVisitor)
            }
        }
    }

    private fun structDecl(writer: SwiftWriter, shape: StructureShape, isRecursiveMember: Boolean, block: () -> Unit) {
        var symbol = if (isRecursiveMember) symbolProvider.toSymbol(shape).recursiveSymbol() else symbolProvider.toSymbol(shape)

        /*
            The following line changes the generated code from structure instantiation to
            Box<T> class instantiation for recursive members.

            Changes the instantiation of recursive structure from:-
                RecursiveShapesInputOutputNested1(
                    foo: "Foo1",
                    nested: RecursiveShapesInputOutputNested2(
                        bar: "Bar1"
                    )
                 )

            To:-
            RecursiveShapesInputOutputNested1(
            foo: "Foo1",
            nested: Box<RecursiveShapesInputOutputNested2>(
                value: RecursiveShapesInputOutputNested2(
                    bar: "Bar1"
                )
            )
        )
        */
        if (isRecursiveMember) {
            writer.writeInline("\$L(", symbol.name)
                .indent()
                .writeInline("\nvalue: ")

            symbol = symbolProvider.toSymbol(shape)
        }
        /*
            The only change with recursive member is that "Box<T>( value: " appended
            and the rest of the logic is same as non-recursive members. So, there is no "else" here.
         */
        writer.writeInline("\$L(", symbol.name)
            .indent()
            .call { block() }
            .dedent()
                // TODO:: fix indentation when `writeInline` retains indent
            .writeInline("\n)")

        if (isRecursiveMember) {
            writer.dedent()
                .writeInline("\n)")
        }
    }

    private fun unionDecl(writer: SwiftWriter, shape: UnionShape, block: () -> Unit) {
        val symbol = symbolProvider.toSymbol(shape)
        writer.writeInline("\$L.", symbol.name).call { block() }.write(")")
    }

    private fun mapDecl(writer: SwiftWriter, shape: MapShape, block: () -> Unit) {
        writer.pushState()
        writer.trimTrailingSpaces(false)
        writer.writeInline("[")
            .indent()
            .call { block() }
            .dedent()
            .write("]")

        writer.popState()
    }

    private fun collectionDecl(writer: SwiftWriter, shape: CollectionShape, block: () -> Unit) {
        writer.pushState()
        writer.trimTrailingSpaces(false)

        val targetMemberShape = model.expectShape(shape.member.target)
        val memberSymbol = symbolProvider.toSymbol(targetMemberShape)
        if (shape.isSetShape) {
            writer.writeInline("Set<\$L>(arrayLiteral: ", memberSymbol.name)
                .indent()
                .call { block() }
                .dedent()
                .writeInline("\n)")
        } else if (shape.isListShape) {
            writer.writeInline("[")
                .indent()
                .call { block() }
                .dedent()
                .writeInline("\n]")
        }
        writer.popState()
    }

    private fun primitiveDecl(writer: SwiftWriter, shape: Shape, block: () -> Unit) {
        val suffix = when (shape.type) {
            ShapeType.STRING -> {
                if (shape.hasTrait(EnumTrait::class.java)) {
                    val symbol = symbolProvider.toSymbol(shape)
                    writer.writeInline("\$L(rawValue: ", symbol.name)
                    ")!"
                } else { "" }
            }
            ShapeType.BLOB -> {
                //  val symbol = symbolProvider.toSymbol(shape)
                // FIXME: properly handle this optional with an unwrapped statement before it's passed as a value to a shape.
                    ".data(using: .utf8)!"
            }
            else -> { "" }
        }

        block()

        if (suffix.isNotBlank()) {
            writer.writeInline(suffix)
        }
    }

    /**
     * NodeVisitor to walk shape value declarations with node values.
     */
    private class ShapeValueNodeVisitor(
        val writer: SwiftWriter,
        val generator: ShapeValueGenerator,
        val currShape: Shape
    ) : NodeVisitor<Unit> {

        override fun objectNode(node: ObjectNode) {
            var i = 0
            // this is important because when a struct is generated in swift it is generated with its members sorted by name.
            // when you instantiate that struct you have to call params in order with their param names. if you don't it won't compile
            // so we sort here before we write any of the members with their values
            val sortedMembers = node.members.toSortedMap(compareBy<StringNode> { it.value })
            sortedMembers.forEach { (keyNode, valueNode) ->
                val memberShape: Shape
                when (currShape) {
                    is StructureShape -> {
                        val member = currShape.getMember(keyNode.value).orElseThrow {
                            CodegenException("unknown member ${currShape.id}.${keyNode.value}")
                        }
                        val isRecursiveMember = member.hasTrait(SwiftBoxTrait::class.java)
                        memberShape = generator.model.expectShape(member.target)
//                        memberShape = RecursiveShapeBoxer.extractShapeOfMember(generator.model, member)
                        val memberName = generator.symbolProvider.toMemberName(member)
                        // NOTE - `write()` appends a newline and keeps indentation,
                        // `writeInline()` doesn't keep indentation but also doesn't append a newline
                        // ...except it does insert indentation if it encounters a newline.
                        // This is our workaround for the moment to keep indentation but not insert
                        // a newline at the end.
                        writer.writeInline("\n\$L: ", memberName)
                        generator.writeShapeValueInline(writer, memberShape, valueNode, isRecursiveMember)
                        if (i < node.members.size - 1) {
                            writer.writeInline(",")
                        }
                    }
                    is MapShape -> {
                        memberShape = generator.model.expectShape(currShape.value.target)
                        writer.writeInline("\n\$S: ", keyNode.value)
                        if (valueNode.isNullNode) {
                            writer.writeInline("nil")
                        } else {
                            generator.writeShapeValueInline(writer, memberShape, valueNode)
                        }
                        if (i < node.members.size - 1) {
                            writer.writeInline(",")
                        }
                    }
                    is DocumentShape -> {
                        // TODO - deal with document shapes
                    }
                    is UnionShape -> {
                        val member = currShape.getMember(keyNode.value).orElseThrow {
                            CodegenException("unknown member ${currShape.id}.${keyNode.value}")
                        }
                        memberShape = generator.model.expectShape(member.target)
                        writer.writeInline("\$L(", keyNode.value)
                        generator.writeShapeValueInline(writer, memberShape, valueNode)
                    }
                    else -> throw CodegenException("unexpected shape type " + currShape.type)
                }
                i++
            }
            if (sortedMembers.isEmpty()) {
                when (currShape) {
                    is MapShape -> writer.writeInline(":") // to pass an empty map you need to have a colon like `[:]`
                }
            }
        }

        override fun stringNode(node: StringNode) {
            writer.writeInline("\$S", node.value)
        }

        override fun nullNode(node: NullNode) {
            writer.writeInline("nil")
        }

        override fun arrayNode(node: ArrayNode) {
            val memberShape = generator.model.expectShape((currShape as CollectionShape).member.target)
            var i = 0
            node.elements.forEach { element ->
                writer.writeInline("\n")
                generator.writeShapeValueInline(writer, memberShape, element)
                if (i < node.elements.size - 1) {
                    writer.writeInline(",")
                }
                i++
            }
        }

        override fun numberNode(node: NumberNode) {
            when (currShape.type) {
                ShapeType.TIMESTAMP -> {
                    writer.writeInline("Date(timeIntervalSince1970: \$L)", node.value)
                }

                ShapeType.BYTE, ShapeType.SHORT, ShapeType.INTEGER,
                ShapeType.LONG, ShapeType.DOUBLE, ShapeType.FLOAT -> writer.writeInline("\$L", node.value)

                /*
                TODO:: When https://github.com/apple/swift-numerics supports Integer conforming to Real protocol,
                        we need to change "Array(String($L).utf8)" to Complex<Integer>. Apple's work is being
                        tracked in apple/swift-numerics#5
                 */
                ShapeType.BIG_INTEGER -> {
                    writer.addImport(SwiftDependency.BIG.namespace)
                    writer.writeInline("Array(String(\$L).utf8)", node.value)
                }

                ShapeType.BIG_DECIMAL -> {
                    writer.addImport(SwiftDependency.BIG.namespace)
                    writer.writeInline("Complex(\$L)", (node.value as Double).toBigDecimal())
                }
                else -> throw CodegenException("unexpected shape type $currShape for numberNode")
            }
        }

        override fun booleanNode(node: BooleanNode) {
            if (currShape.type != ShapeType.BOOLEAN) {
                throw CodegenException("unexpected shape type $currShape for boolean value")
            }

            writer.writeInline("\$L", if (node.value) "true" else "false")
        }
    }
}

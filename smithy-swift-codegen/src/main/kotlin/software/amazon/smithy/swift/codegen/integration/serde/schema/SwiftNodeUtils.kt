package software.amazon.smithy.swift.codegen.integration.serde.schema

import software.amazon.smithy.model.node.ArrayNode
import software.amazon.smithy.model.node.BooleanNode
import software.amazon.smithy.model.node.Node
import software.amazon.smithy.model.node.NullNode
import software.amazon.smithy.model.node.NumberNode
import software.amazon.smithy.model.node.ObjectNode
import software.amazon.smithy.model.node.StringNode
import software.amazon.smithy.swift.codegen.SwiftWriter

fun Node.toSwiftNode(writer: SwiftWriter): String =
    when (this) {
        is ObjectNode -> {
            if (members.isEmpty()) {
                writer.format("[:]")
            } else {
                val contents =
                    members.map {
                        writer.format("\$S:\$L", it.key, it.value.toSwiftNode(writer))
                    }
                writer.format("[\$L]", contents.joinToString(","))
            }
        }
        is ArrayNode -> {
            val contents = elements.map { it.toSwiftNode(writer) }
            writer.format("[\$L]", contents.joinToString(","))
        }
        is StringNode -> {
            writer.format("\$S", value)
        }
        is NumberNode -> {
            writer.format("\$L", value)
        }
        is BooleanNode -> {
            writer.format("\$L", value)
        }
        is NullNode -> {
            writer.format("nil")
        }
        else -> {
            throw Exception("Unknown node type")
        }
    }

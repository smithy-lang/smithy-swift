package software.amazon.smithy.swift.codegen.integration.serde.schema

import software.amazon.smithy.model.node.ArrayNode
import software.amazon.smithy.model.node.BooleanNode
import software.amazon.smithy.model.node.Node
import software.amazon.smithy.model.node.NullNode
import software.amazon.smithy.model.node.NumberNode
import software.amazon.smithy.model.node.ObjectNode
import software.amazon.smithy.model.node.StringNode

fun Node.toSwiftNode(): String {
    when (this) {
        is ObjectNode -> {
            return if (members.isEmpty()) {
                "[:]"
            } else {
                "[" + members.map { "\"${it.key}\":${it.value.toSwiftNode()}" }.joinToString(",") + "]"
            }
        }
        is ArrayNode -> {
            return "[" + elements.joinToString(",") { it.toSwiftNode() } + "]"
        }
        is StringNode -> {
            return "\"" + value + "\""
        }
        is NumberNode -> {
            return "$value"
        }
        is BooleanNode -> {
            return "$value"
        }
        is NullNode -> {
            return "nil"
        }
        else -> {
            throw Exception("Unknown node type")
        }
    }
}
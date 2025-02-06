/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

// copied and modified from: https://github.com/awslabs/smithy-kotlin/blob/b386392b1cd7cc73a9bc08bedcff0c109487b74f/smithy-kotlin-codegen/src/main/kotlin/software/amazon/smithy/kotlin/codegen/model/SymbolBuilder.kt
package software.amazon.smithy.swift.codegen.model

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolDependencyContainer
import software.amazon.smithy.codegen.core.SymbolReference
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter

@DslMarker
annotation class SymbolDsl

/**
 * Kotlin DSL wrapper around Symbol.Builder
 */
@SymbolDsl
open class SymbolBuilder {
    private val builder = Symbol.builder()
    var name: String? = null
    var nullable: Boolean = true
    var namespace: String? = null

    var definitionFile: String? = null
    var declarationFile: String? = null
    var defaultValue: String? = null

    val dependencies: MutableList<SymbolDependencyContainer> = mutableListOf()
    private val references: MutableList<SymbolReference> = mutableListOf()

    fun dependency(dependency: SymbolDependencyContainer) = dependencies.add(dependency)

    fun reference(ref: SymbolReference) = references.add(ref)

    fun reference(
        symbol: Symbol,
        vararg options: SymbolReference.ContextOption,
    ) {
        if (options.isEmpty()) {
            builder.addReference(symbol)
        } else {
            val ref =
                SymbolReference
                    .builder()
                    .symbol(symbol)
                    .options(options.toSet())
                    .build()
            references += ref
        }
    }

    fun reference(block: SymbolBuilder.() -> Unit) {
        val refSymbol = SymbolBuilder().apply(block).build()
        reference(refSymbol)
    }

    fun setProperty(
        key: String,
        value: Any,
    ) {
        builder.putProperty(key, value)
    }

    fun removeProperty(key: String) {
        builder.removeProperty(key)
    }

    fun properties(block: PropertiesBuilder.() -> Unit) {
        val propBuilder =
            object : PropertiesBuilder {
                override fun set(
                    key: String,
                    value: Any,
                ) = setProperty(key, value)

                override fun remove(key: String) = removeProperty(key)
            }

        block(propBuilder)
    }

    interface PropertiesBuilder {
        fun set(
            key: String,
            value: Any,
        )

        fun remove(key: String)
    }

    fun build(): Symbol {
        builder.name(name)
        if (nullable) {
            builder.boxed()
        }

        namespace?.let { builder.namespace(namespace, ".") }
        declarationFile?.let { builder.declarationFile(it) }
        definitionFile?.let { builder.definitionFile(it) }
        defaultValue?.let { builder.defaultValue(it) }
        dependencies.forEach { builder.addDependency(it) }
        references.forEach { builder.addReference(it) }

        return builder.build()
    }
}

/**
 * Build a symbol inside the given block
 */
fun buildSymbol(block: SymbolBuilder.() -> Unit): Symbol = SymbolBuilder().apply(block).build()

fun SymbolBuilder.namespace(
    dependency: SwiftDependency,
    type: String = "",
) {
    namespace =
        if (type.isNotEmpty()) {
            "${dependency.target}.$type"
        } else {
            dependency.target
        }

    dependency(dependency)
}

fun Symbol.isGeneric(): Boolean = this.getProperty("isGeneric").orElse(false) as Boolean

fun Symbol.isOptional(): Boolean = this.getProperty("isOptional").orElse(false) as Boolean

fun Symbol.toOptional(): Symbol =
    this
        .toBuilder()
        .putProperty("isOptional", true)
        .name(name)
        .build()

fun Symbol.toGeneric(): Symbol =
    this
        .toBuilder()
        .putProperty("isGeneric", true)
        .name(name)
        .build()

fun Symbol.renderSwiftType(writer: SwiftWriter): String = writer.format("\$N", this)

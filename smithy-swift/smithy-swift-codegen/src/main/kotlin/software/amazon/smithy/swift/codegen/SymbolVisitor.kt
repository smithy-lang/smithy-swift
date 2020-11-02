/*
 * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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

import java.util.logging.Logger
import software.amazon.smithy.codegen.core.*
import software.amazon.smithy.codegen.core.ReservedWordSymbolProvider.Escaper
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.*
import software.amazon.smithy.model.traits.BoxTrait
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.model.traits.ErrorTrait
import software.amazon.smithy.swift.codegen.SwiftSettings.Companion.reservedKeywords
import software.amazon.smithy.utils.StringUtils

// PropertyBag keys

// The key that holds the default value for a type (symbol) as a string
private const val DEFAULT_VALUE_KEY: String = "defaultValue"

// Boolean property indicating this symbol should be boxed
private const val BOXED_KEY: String = "boxed"

/**
 * Test if a symbol is boxed or not
 */
fun Symbol.isBoxed(): Boolean {
    return getProperty(BOXED_KEY).map {
        when (it) {
            is Boolean -> it
            else -> false
        }
    }.orElse(false)
}

/**
 * Obtains the symbol for a recursive symbol to represent the symbol as Box<T>
 */
fun Symbol.recursiveSymbol(): Symbol {
    return Symbol.builder()
        .addDependency(SwiftDependency.CLIENT_RUNTIME)
        .name("Box<$name>")
        .putProperty("boxed", isBoxed())
        .putProperty("defaultValue", defaultValue())
        .build()
}

/**
 * Gets the default value for the symbol if present, else null
 */
fun Symbol.defaultValue(): String? {
    // boxed types should always be defaulted to null
    if (isBoxed()) {
        return "nil"
    }

    val default = getProperty(DEFAULT_VALUE_KEY, String::class.java)
    return if (default.isPresent) default.get() else null
}

fun Shape.defaultName(): String = StringUtils.capitalize(this.id.name)

fun Shape.camelCaseName(): String = StringUtils.uncapitalize(this.id.name)

class SymbolVisitor(private val model: Model, private val rootNamespace: String = "") : SymbolProvider,
    ShapeVisitor<Symbol> {

    private val logger = Logger.getLogger(CodegenVisitor::class.java.name)
    private var escaper: Escaper
    // model depth; some shapes use `toSymbol()` internally as they convert (e.g.) member shapes to symbols, this tracks
    // how deep in the model we have recursed
    private var depth = 0

    // private val errorShapes: Set<StructureShape> = HashSet()

    init {
        // Load reserved words from a new-line delimited file.
        // val resource = SwiftCodegenPlugin::class.java.classLoader.getResource("software.amazon.smithy.swift.codegen/reserved-words.txt")
        // TODO:: fix java.io.UncheckedIOException: java.util.zip.ZipException: ZipFile invalid LOC header (bad signature)

        val reservedWords = ReservedWordsBuilder().apply {
            reservedKeywords.forEach { put(it, escapeReservedWords(it)) }
        }.build()

        escaper = ReservedWordSymbolProvider.builder()
            .nameReservedWords(reservedWords) // Only escape words when the symbol has a definition file to
            .memberReservedWords(reservedWords)
            // prevent escaping intentional references to built-in types.
            .escapePredicate { _, symbol: Symbol -> symbol.definitionFile.isNotEmpty() }
            .buildEscaper()

        // TODO: Get each structure that's used an error.
//        val operationIndex = model.getKnowledge(OperationIndex::class.java)
//        model.shapes(OperationShape::class.java)
//            .forEach { operationShape: OperationShape? ->
//                errorShapes.plus(operationIndex.getErrors(operationShape))
//            }
    }

    private fun escapeReservedWords(word: String): String = "`$word`"

    override fun toSymbol(shape: Shape): Symbol {
        depth++
        val symbol = shape.accept(this)
        depth--
        this.logger.fine("Creating symbol from $shape: $symbol")
        return escaper.escapeSymbol(shape, symbol)
    }

    override fun toMemberName(shape: MemberShape): String {
        return escaper.escapeMemberName(shape.memberName).decapitalize()
    }

    override fun integerShape(shape: IntegerShape): Symbol = numberShape(shape, "Int", "0")

    override fun floatShape(shape: FloatShape): Symbol = numberShape(shape, "Float", "0.0")

    override fun longShape(shape: LongShape): Symbol = numberShape(shape, "Int", "0")

    override fun doubleShape(shape: DoubleShape): Symbol = numberShape(shape, "Double", "0.0")

    override fun byteShape(shape: ByteShape): Symbol = numberShape(shape, "Int8", "0")

    override fun shortShape(shape: ShortShape): Symbol = numberShape(shape, "Int16", "0")

    override fun bigIntegerShape(shape: BigIntegerShape): Symbol = createBigSymbol(shape, "Complex<Int>")

    override fun bigDecimalShape(shape: BigDecimalShape): Symbol = createBigSymbol(shape, "Complex<Double>")

    private fun createBigSymbol(shape: Shape?, symbolName: String): Symbol {
        return createSymbolBuilder(shape, symbolName, namespace = "ComplexModule", boxed = true)
            .addDependency(SwiftDependency.BIG)
            .build()
    }

    override fun stringShape(shape: StringShape): Symbol {
        val enumTrait = shape.getTrait(EnumTrait::class.java)
        if (enumTrait.isPresent) {
            return createEnumSymbol(shape)
        }
        return createSymbolBuilder(shape, "String", boxed = true).build()
    }

    private fun createEnumSymbol(shape: Shape): Symbol {
        val name = shape.defaultName()
        val builder = createSymbolBuilder(shape, name, boxed = true)
            .definitionFile(formatModuleName(shape.type, name))

        // add a reference to each member symbol
        if (shape is UnionShape) {
            addDeclareMemberReferences(builder, shape.allMembers.values)
        }
        return builder.build()
    }

    override fun booleanShape(shape: BooleanShape): Symbol {
        return createSymbolBuilder(shape, "Bool").putProperty(DEFAULT_VALUE_KEY, "false").build()
    }

    override fun structureShape(shape: StructureShape): Symbol {
        val name = shape.defaultName()
        val builder = createSymbolBuilder(shape, name, boxed = true)
            .definitionFile(formatModuleName(shape.type, name))

        // add a reference to each member symbol
        addDeclareMemberReferences(builder, shape.allMembers.values)

        if (shape.getTrait(ErrorTrait::class.java).isPresent) {
            builder.addDependency(SwiftDependency.CLIENT_RUNTIME)
            builder.namespace("ClientRuntime", ".")
        }
        return builder.build()
    }

    override fun listShape(shape: ListShape): Symbol {
        val reference = toSymbol(shape.member)
        val suffix = if (reference.isBoxed()) "?" else ""
        val referenceTypeName = "${reference.name}$suffix"
        return createSymbolBuilder(shape, "[$referenceTypeName]", true).addReference(reference).build()
    }

    override fun mapShape(shape: MapShape): Symbol {
        val reference = toSymbol(shape.value)
        val suffix = if (reference.isBoxed()) "?" else ""
        val referenceTypeName = "${reference.name}$suffix"
        return createSymbolBuilder(shape, "[String:$referenceTypeName]", true).addReference(reference).build()
    }

    override fun setShape(shape: SetShape): Symbol {
        val reference = toSymbol(shape.member)
        val suffix = if (reference.isBoxed()) "?" else ""
        val referenceTypeName = "${reference.name}$suffix"
        return createSymbolBuilder(shape, "Set<$referenceTypeName>", true).addReference(reference)
            .build()
    }

    override fun resourceShape(shape: ResourceShape): Symbol {
        // TODO create resource type
        return createSymbolBuilder(shape, "Any", true).build()
    }

    override fun memberShape(shape: MemberShape): Symbol {
        val targetShape =
            model.getShape(shape.target).orElseThrow { CodegenException("Shape not found: ${shape.target}") }
        return toSymbol(targetShape)
    }

    override fun timestampShape(shape: TimestampShape): Symbol {
        return createSymbolBuilder(shape, "Date", "Foundation", true)
            .build()
    }

    override fun unionShape(shape: UnionShape): Symbol {
        return createEnumSymbol(shape)
    }

    override fun operationShape(shape: OperationShape): Symbol {
        return createSymbolBuilder(shape, "func").build()
    }

    override fun blobShape(shape: BlobShape): Symbol {
        return createSymbolBuilder(shape, "Data", "Foundation", true).build()
    }

    override fun documentShape(shape: DocumentShape): Symbol {
        return createSymbolBuilder(shape, "JSONValue", "ClientRuntime", true)
            .addDependency(SwiftDependency.CLIENT_RUNTIME)
            .build()
    }

    override fun serviceShape(shape: ServiceShape): Symbol {
        val name = shape.defaultName()
        return createSymbolBuilder(shape, "${name}Client", "ClientRuntime")
            .addDependency(SwiftDependency.CLIENT_RUNTIME)
            .definitionFile(formatModuleName(shape.type, name))
            .build()
    }

    private fun numberShape(shape: Shape?, typeName: String, defaultValue: String = "0"): Symbol {
        return createSymbolBuilder(shape, typeName).putProperty(DEFAULT_VALUE_KEY, defaultValue).build()
    }

    /**
     * Creates a symbol builder for the shape with the given type name in the root namespace.
     */
    private fun createSymbolBuilder(shape: Shape?, typeName: String, boxed: Boolean = false): Symbol.Builder {
        val builder = Symbol.builder().putProperty("shape", shape).name(typeName)
        val explicitlyBoxed = shape?.hasTrait(BoxTrait::class.java) ?: false
        if (explicitlyBoxed || boxed) {
            builder.putProperty(BOXED_KEY, true)
        }
        return builder
    }

    /**
     * Creates a symbol builder for the shape with the given type name in a child namespace relative
     * to the root namespace e.g. `relativeNamespace = bar` with a root namespace of `foo` would set
     * the namespace (and ultimately the package name) to `foo.bar` for the symbol.
     */
    private fun createSymbolBuilder(
        shape: Shape?,
        typeName: String,
        namespace: String,
        boxed: Boolean = false
    ): Symbol.Builder {
        return createSymbolBuilder(shape, typeName, boxed)
            .namespace(namespace, ".")
    }

    private fun formatModuleName(shapeType: ShapeType, name: String): String? {
        // All shapes except for the service are stored in models.
        return when (shapeType) {
            ShapeType.SERVICE -> "./$rootNamespace/${name}ClientProtocol.swift"
            else -> "./$rootNamespace/models/$name.swift"
        }
    }

    /**
     * Add all the [members] as references needed to declare the given symbol being built.
     */
    private fun addDeclareMemberReferences(builder: Symbol.Builder, members: Collection<MemberShape>) {
        // when converting a shape to a symbol we only need references to top level members
        // in order to declare the symbol. This prevents recursive shapes from causing a stack overflow (and doing
        // unnecessary work since we don't need the inner references)
        if (depth > 1) return
        members.forEach {
            val memberSymbol = toSymbol(it)
            val ref = SymbolReference.builder()
                .symbol(memberSymbol)
                .options(SymbolReference.ContextOption.DECLARE)
                .build()
            builder.addReference(ref)

            val targetShape = model.expectShape(it.target)
            if (targetShape is CollectionShape) {
                val targetSymbol = toSymbol(targetShape)
                targetSymbol.references.forEach { builder.addReference(it) }
            }
        }
    }

    companion object {
        /**
         * Check if a given string can be a valid swift identifier.
         * Valid swift identifier has only alphanumerics and underscore and does not start with a number
         */
        fun isValidSwiftIdentifier(value: String): Boolean {
            return !value.contains(Regex("[^a-zA-Z0-9_]")) &&
                    !Character.isDigit(value.first())
        }
    }
}

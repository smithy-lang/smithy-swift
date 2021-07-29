/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.codegen.core.ReservedWordSymbolProvider
import software.amazon.smithy.codegen.core.ReservedWordSymbolProvider.Escaper
import software.amazon.smithy.codegen.core.ReservedWordsBuilder
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.codegen.core.SymbolReference
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.BigDecimalShape
import software.amazon.smithy.model.shapes.BigIntegerShape
import software.amazon.smithy.model.shapes.BlobShape
import software.amazon.smithy.model.shapes.BooleanShape
import software.amazon.smithy.model.shapes.ByteShape
import software.amazon.smithy.model.shapes.CollectionShape
import software.amazon.smithy.model.shapes.DocumentShape
import software.amazon.smithy.model.shapes.DoubleShape
import software.amazon.smithy.model.shapes.FloatShape
import software.amazon.smithy.model.shapes.IntegerShape
import software.amazon.smithy.model.shapes.ListShape
import software.amazon.smithy.model.shapes.LongShape
import software.amazon.smithy.model.shapes.MapShape
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.OperationShape
import software.amazon.smithy.model.shapes.ResourceShape
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.shapes.SetShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeType
import software.amazon.smithy.model.shapes.ShapeVisitor
import software.amazon.smithy.model.shapes.ShortShape
import software.amazon.smithy.model.shapes.StringShape
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.model.shapes.TimestampShape
import software.amazon.smithy.model.shapes.UnionShape
import software.amazon.smithy.model.traits.BoxTrait
import software.amazon.smithy.model.traits.EnumTrait
import software.amazon.smithy.model.traits.ErrorTrait
import software.amazon.smithy.model.traits.SparseTrait
import software.amazon.smithy.model.traits.StreamingTrait
import software.amazon.smithy.swift.codegen.SwiftSettings.Companion.reservedKeywords
import software.amazon.smithy.swift.codegen.model.SymbolProperty
import software.amazon.smithy.swift.codegen.model.boxed
import software.amazon.smithy.swift.codegen.model.defaultName
import software.amazon.smithy.swift.codegen.model.hasTrait
import software.amazon.smithy.swift.codegen.utils.toPascalCase
import software.amazon.smithy.utils.StringUtils.lowerCase
import java.util.logging.Logger

class SymbolVisitor(private val model: Model, swiftSettings: SwiftSettings) :
    SymbolProvider,
    ShapeVisitor<Symbol> {

    private val rootNamespace = swiftSettings.moduleName
    private val sdkId = swiftSettings.sdkId
    private val service: ServiceShape? = try { swiftSettings.getService(model) } catch (e: CodegenException) { null }
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

    override fun toSymbol(shape: Shape): Symbol {
        depth++
        val symbol = shape.accept(this)
        depth--
        this.logger.fine("Creating symbol from $shape: $symbol")
        return escaper.escapeSymbol(shape, symbol)
    }

    override fun toMemberName(shape: MemberShape): String {
        val containingShape = model.expectShape(shape.container)
        if (containingShape is UnionShape) {
            val name = escaper.escapeMemberName(shape.memberName)
            return if (!name.equals("sdkUnknown")) lowerCase(name) else name
        }
        return escaper.escapeMemberName(shape.memberName.decapitalize())
    }

    override fun integerShape(shape: IntegerShape): Symbol = numberShape(shape, "Int", "0")

    override fun floatShape(shape: FloatShape): Symbol = numberShape(shape, "Float", "0.0")

    override fun longShape(shape: LongShape): Symbol = numberShape(shape, "Int", "0")

    override fun doubleShape(shape: DoubleShape): Symbol = numberShape(shape, "Double", "0.0")

    override fun byteShape(shape: ByteShape): Symbol = numberShape(shape, "Int8", "0")

    override fun shortShape(shape: ShortShape): Symbol = numberShape(shape, "Int16", "0")

    /*
    TODO:: When https://github.com/apple/swift-numerics supports Integer conforming to Real protocol, we need to
            change  [UInt8] to Complex<Integer>. Apple's work is being tracked in apple/swift-numerics#5
     */
    override fun bigIntegerShape(shape: BigIntegerShape): Symbol = createBigSymbol(shape, "[UInt8]")

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
        val name = shape.defaultName(service)
        val builder = createSymbolBuilder(shape, name, boxed = true)
            .definitionFile(formatModuleName(shape.type, name))

        // add a reference to each member symbol
        if (shape is UnionShape) {
            addDeclareMemberReferences(builder, shape.allMembers.values)
        }
        return builder.build()
    }

    override fun booleanShape(shape: BooleanShape): Symbol {
        return createSymbolBuilder(shape, "Bool").putProperty(SymbolProperty.DEFAULT_VALUE_KEY, "false").build()
    }

    override fun structureShape(shape: StructureShape): Symbol {
        val name = shape.defaultName(service)
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
        val referenceTypeName = if (shape.hasTrait<SparseTrait>()) "${reference.name}?" else "${reference.name}"
        return createSymbolBuilder(shape, "[$referenceTypeName]", true).addReference(reference).build()
    }

    override fun mapShape(shape: MapShape): Symbol {
        val reference = toSymbol(shape.value)
        val referenceTypeName = if (shape.hasTrait<SparseTrait>()) "${reference.name}?" else "${reference.name}"
        return createSymbolBuilder(shape, "[String:$referenceTypeName]", true).addReference(reference).build()
    }

    override fun setShape(shape: SetShape): Symbol {
        val reference = toSymbol(shape.member)
        return createSymbolBuilder(shape, "Set<${reference.name}>", true).addReference(reference)
            .build()
    }

    override fun resourceShape(shape: ResourceShape): Symbol {
        // TODO create resource type
        return createSymbolBuilder(shape, "Any", true).build()
    }

    override fun memberShape(shape: MemberShape): Symbol {
        val targetShape = model.getShape(shape.target).orElseThrow { CodegenException("Shape not found: ${shape.target}") }
        return toSymbol(targetShape)
    }

    override fun timestampShape(shape: TimestampShape): Symbol {
        return createSymbolBuilder(shape, "Date", "ClientRuntime", true)
            .build()
    }

    override fun unionShape(shape: UnionShape): Symbol {
        return createEnumSymbol(shape)
    }

    override fun operationShape(shape: OperationShape): Symbol {
        // The Swift SDK does not produce code explicitly based on Operations
        error { "Unexpected codegen code path" }
    }

    override fun blobShape(shape: BlobShape): Symbol {
        if (shape.hasTrait<StreamingTrait>()) {
            return createSymbolBuilder(shape, "ByteStream", "ClientRuntime", true).build()
        } else {
            return createSymbolBuilder(shape, "Data", "ClientRuntime", true).build()
        }
    }

    override fun documentShape(shape: DocumentShape): Symbol {
        return createSymbolBuilder(shape, "Document", "ClientRuntime", true)
            .addDependency(SwiftDependency.CLIENT_RUNTIME)
            .build()
    }

    override fun serviceShape(shape: ServiceShape): Symbol {
        val name = sdkId.clientName()
        return createSymbolBuilder(shape, "${name}Client", "ClientRuntime")
            .addDependency(SwiftDependency.CLIENT_RUNTIME)
            .definitionFile(formatModuleName(shape.type, name))
            .build()
    }

    private fun numberShape(shape: Shape?, typeName: String, defaultValue: String = "0"): Symbol {
        return createSymbolBuilder(shape, typeName).putProperty(SymbolProperty.DEFAULT_VALUE_KEY, defaultValue).build()
    }

    /**
     * Creates a symbol builder for the shape with the given type name in the root namespace.
     */
    private fun createSymbolBuilder(shape: Shape?, typeName: String, boxed: Boolean = false): Symbol.Builder {
        val builder = Symbol.builder().putProperty("shape", shape).name(typeName)
        val explicitlyBoxed = shape?.hasTrait<BoxTrait>() ?: false
        if (explicitlyBoxed || boxed) {
            builder.boxed()
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

        fun escapeReservedWords(word: String): String = "`$word`"
    }
}

// See https://awslabs.github.io/smithy/1.0/spec/aws/aws-core.html#using-sdk-service-id-for-client-naming
fun String.clientName(): String = toPascalCase()

fun SymbolProvider.toMemberNames(shape: MemberShape): Pair<String, String> {
    val escapedName = toMemberName(shape)
    return Pair(escapedName, escapedName.removeSurroundingBackticks())
}

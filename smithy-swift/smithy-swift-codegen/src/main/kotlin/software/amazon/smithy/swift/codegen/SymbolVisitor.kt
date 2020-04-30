package software.amazon.smithy.swift.codegen

import java.util.*
import java.util.logging.Logger
import software.amazon.smithy.codegen.core.*
import software.amazon.smithy.codegen.core.ReservedWordSymbolProvider.Escaper
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.*
import software.amazon.smithy.model.traits.BoxTrait
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

fun Shape.defaultStructName(): String = StringUtils.capitalize(this.id.name)

class SymbolVisitor(private val model: Model, private val rootNamespace: String = "") : SymbolProvider,
    ShapeVisitor<Symbol> {

    private val logger = Logger.getLogger(CodegenVisitor::class.java.name)
    private var escaper: Escaper
    // private val errorShapes: Set<StructureShape> = HashSet()

    init {
        // Load reserved words from a new-line delimited file.
        val resource = SwiftCodegenPlugin::class.java.classLoader.getResource("software.amazon.smithy.swift.codegen/reserved-words.txt")
        val reservedWords = ReservedWordsBuilder()
            .loadWords(resource, ::escapeReservedWords)
            .build()

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
        val symbol = shape.accept(this)
        this.logger.fine("Creating symbol from $shape: $symbol")
        return escaper.escapeSymbol(shape, symbol)
    }

    override fun toMemberName(shape: MemberShape): String {
        return escaper.escapeMemberName(shape.memberName)
    }

    override fun integerShape(shape: IntegerShape): Symbol = numberShape(shape, "Int", "0")

    override fun floatShape(shape: FloatShape): Symbol = numberShape(shape, "Float", "0.0")

    override fun longShape(shape: LongShape): Symbol = numberShape(shape, "Int", "0")

    override fun doubleShape(shape: DoubleShape): Symbol = numberShape(shape, "Double", "0.0")

    override fun bigDecimalShape(shape: BigDecimalShape): Symbol = numberShape(shape, "NSDecimal")

    override fun byteShape(shape: ByteShape): Symbol = numberShape(shape, "Int8", "0")

    override fun shortShape(shape: ShortShape): Symbol = numberShape(shape, "Int16", "0")

    // TODO: support BigInt type via apple prototype or third party
    override fun bigIntegerShape(shape: BigIntegerShape): Symbol = numberShape(shape, "Int", "0")

    override fun stringShape(shape: StringShape): Symbol {
        return createSymbolBuilder(shape, "String", true).build()
    }

    override fun booleanShape(shape: BooleanShape): Symbol {
        return createSymbolBuilder(shape, "Bool").putProperty(DEFAULT_VALUE_KEY, "false").build()
    }

    override fun structureShape(shape: StructureShape): Symbol {
        val name = shape.defaultStructName()
        val namespace = "./$rootNamespace/models/"
        // TODO: handle error types
        return createSymbolBuilder(shape, name, boxed = true).definitionFile("${namespace}${toFilename(shape.id.name)}").build()
    }

    override fun listShape(shape: ListShape): Symbol {
        val reference = toSymbol(shape.member)
        return createSymbolBuilder(shape, "[${reference.name}]", true).build()
    }

    override fun mapShape(shape: MapShape): Symbol {
        val reference = toSymbol(shape.value)
        return createSymbolBuilder(shape, "[String:${reference.name}]", true).build()
    }

    override fun setShape(shape: SetShape): Symbol {
        val reference = toSymbol(shape.member)
        return createSymbolBuilder(shape, "Set<${reference.name}>", true)
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
        return createSymbolBuilder(shape, "Date", true).build()
    }

    override fun unionShape(shape: UnionShape): Symbol {
        return createSymbolBuilder(shape, "enum").build()
    }

    override fun operationShape(shape: OperationShape): Symbol {
        // TODO create operation type
        return createSymbolBuilder(shape, "func").build()
    }

    override fun blobShape(shape: BlobShape): Symbol {
        return createSymbolBuilder(shape, "Data", true).build()
    }

    override fun documentShape(shape: DocumentShape): Symbol {
        // TODO create document type
        return createSymbolBuilder(shape, "Any", true).build()
    }

    override fun serviceShape(shape: ServiceShape): Symbol {
        val name = shape.defaultStructName()
        return createSymbolBuilder(shape, "Client").definitionFile("./${name}Client.swift").build()
    }

    private fun numberShape(shape: Shape?, typeName: String, defaultValue: String = "0"): Symbol {
        return createSymbolBuilder(shape, typeName).putProperty(DEFAULT_VALUE_KEY, defaultValue).build()
    }

//    private fun addFoundationImport(builder: Symbol.Builder, name: String): Symbol.Builder {
//        val importSymbol =
//            Symbol.builder()
//                .name(name)
//                .namespace("Foundation", "")
//                .build()
//        val reference = SymbolReference.builder()
//            .symbol(importSymbol)
//            .options(SymbolReference.ContextOption.DECLARE)
//            .build()
//        return builder.addReference(reference)
//    }

    private fun createSymbolBuilder(shape: Shape?, typeName: String, boxed: Boolean = false): Symbol.Builder {
        val builder = Symbol.builder().putProperty("shape", shape).name(typeName)
        val explicitlyBoxed = shape?.hasTrait(BoxTrait::class.java) ?: false
        if (explicitlyBoxed || boxed) {
            builder.putProperty(BOXED_KEY, true)
        }
        return builder
    }

    private fun formatModuleName(shapeType: ShapeType, name: String): String? {
        // All shapes except for the service and operations are stored in models.
        return when (shapeType) {
            ShapeType.SERVICE -> "./$name"
            ShapeType.OPERATION -> "./operations/$name"
            else -> "./models/$name"
        }
    }

    private fun toFilename(fileName: String): String? {
        return "$fileName.swift"
    }
}

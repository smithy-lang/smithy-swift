package software.amazon.smithy.swift.codegen

import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.shapes.*

class SymbolVisitor(model: Model): SymbolProvider,
    ShapeVisitor<Symbol> {

    override fun toSymbol(shape: Shape?): Symbol {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun integerShape(shape: IntegerShape?): Symbol {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun mapShape(shape: MapShape?): Symbol {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun resourceShape(shape: ResourceShape?): Symbol {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun memberShape(shape: MemberShape?): Symbol {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun floatShape(shape: FloatShape?): Symbol {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun longShape(shape: LongShape?): Symbol {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun stringShape(shape: StringShape?): Symbol {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun unionShape(shape: UnionShape?): Symbol {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun operationShape(shape: OperationShape?): Symbol {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun booleanShape(shape: BooleanShape?): Symbol {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun doubleShape(shape: DoubleShape?): Symbol {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun timestampShape(shape: TimestampShape?): Symbol {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun listShape(shape: ListShape?): Symbol {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun structureShape(shape: StructureShape?): Symbol {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun bigIntegerShape(shape: BigIntegerShape?): Symbol {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun setShape(shape: SetShape?): Symbol {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun bigDecimalShape(shape: BigDecimalShape?): Symbol {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun blobShape(shape: BlobShape?): Symbol {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun documentShape(shape: DocumentShape?): Symbol {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun byteShape(shape: ByteShape?): Symbol {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun shortShape(shape: ShortShape?): Symbol {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }

    override fun serviceShape(shape: ServiceShape?): Symbol {
        TODO("not implemented") //To change body of created functions use File | Settings | File Templates.
    }
}
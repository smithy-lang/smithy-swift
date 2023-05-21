package software.amazon.smithy.swift.codegen.utils

import software.amazon.smithy.aws.traits.protocols.AwsQueryErrorTrait
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.shapes.StructureShape
import software.amazon.smithy.swift.codegen.model.getTrait

fun StructureShape.errorShapeName(symbolProvider: SymbolProvider): String {
    getTrait<AwsQueryErrorTrait>()?.let {
        return it.code
    } ?: run {
        return symbolProvider.toSymbol(this).name
    }
}


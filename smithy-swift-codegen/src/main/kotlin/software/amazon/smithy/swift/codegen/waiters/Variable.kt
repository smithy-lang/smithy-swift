package software.amazon.smithy.swift.codegen.waiters

import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.shapes.Shape

// Holds the name of a variable defined in Swift, plus the optionality and the Smithy
// shape equivalent of its type.
class Variable(

    // The name of the Swift variable that this data is stored in.
    val name: String,

    // true if this variable is an optional, false otherwise.
    // Used to render correct Swift using this variable.
    val isOptional: Boolean,

    // The Smithy shape that is equivalent to this variable's Swift type.
    // (Note that this will never be a MemberShape, rather the member shape's targeted shape.)
    val shape: Shape
) {

    /**
     * Returns the fully namespaced Swift type, without an optional marker, for this variable.
     */
    fun baseSwiftSymbol(symbolProvider: SymbolProvider): String {
        return symbolProvider.toSymbol(shape).fullName
    }

    /**
     * Returns the Swift type, with an optional marker if optional, for this variable.
     */
    fun swiftSymbolWithOptionality(symbolProvider: SymbolProvider): String {
        return baseSwiftSymbol(symbolProvider) + ("?".takeIf { isOptional } ?: "")
    }
}

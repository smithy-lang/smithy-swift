package software.amazon.smithy.swift.codegen

class ImportDeclarations {
    private val imports = mutableSetOf<ImportStatement>()

    fun addImport(packageName: String) {
        imports.add(ImportStatement(packageName))
    }

    override fun toString(): String {
        if (imports.isEmpty()) {
            return ""
        }

        return imports
            .map(ImportStatement::statement)
            .sorted()
            .joinToString(separator = "\n")
    }
}

private data class ImportStatement(val packageName: String) {
    val statement: String
        get() { return "import $packageName" }

    override fun toString(): String = statement
}

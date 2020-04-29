package software.amazon.smithy.swift.codegen


class ImportDeclarations {
    private val imports = setOf(String)

    fun addImport(packageName: String): ImportDeclarations {
        imports.plus(packageName)
        return this;
    }

    override fun toString(): String {
        if (imports.isEmpty()) {
            return ""
        }
        val builder = StringBuilder("")
        for (entry in imports) {
            builder.append("import $entry")
            builder.append('\n')
        }

        return builder.toString()
    }

}
package software.amazon.smithy.swift.codegen.integration

enum class MiddlewarePosition {
    BEFORE {
        override fun stringValue():String = ".before"
    },
    AFTER {
        override fun stringValue(): String = ".after"
    };

    abstract fun stringValue(): String
}
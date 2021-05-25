package software.amazon.smithy.swift.codegen.integration

enum class MiddlewareStep {
    INITIALIZESTEP {
        override fun stringValue(): String = "initializeStep"
    },
    BUILDSTEP {
        override fun stringValue() = "buildStep"
    },
    SERIALIZESTEP {
        override fun stringValue() = "serializeStep"
    },
    FINALIZESTEP {
        override fun stringValue() = "finalizeStep"
    },
    DESERIALIZESTEP {
        override fun stringValue(): String = "deserializeStep"
    };

    abstract fun stringValue(): String
}

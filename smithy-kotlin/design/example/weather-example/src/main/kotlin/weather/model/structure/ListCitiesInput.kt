package weather.model.structure

class ListCitiesInput private constructor(builder: BuilderImpl) {
    val nextToken: String? = builder.nextToken
    val pageSize: Int? = builder.pageSize

    companion object {
        operator fun invoke(block: DslBuilder.() -> Unit) = BuilderImpl().apply(block).build()
        fun dslBuilder(): DslBuilder = BuilderImpl()
    }

    interface DslBuilder {
        var nextToken: String?
        var pageSize: Int?
        fun build(): ListCitiesInput
    }

    private class BuilderImpl : DslBuilder {
        override var nextToken: String? = null
        override var pageSize: Int? = null

        override fun build(): ListCitiesInput = ListCitiesInput(this)
    }
}
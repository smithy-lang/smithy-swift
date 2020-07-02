package weather.model.structure

class ListCitiesOutput private constructor(builder: BuilderImpl) {
    val items: List<CitySummary>? = builder.items
    val nextToken: String? = builder.nextToken

    companion object {
        operator fun invoke(block: DslBuilder.() -> Unit) = BuilderImpl().apply(block).build()
        fun dslBuilder(): DslBuilder = BuilderImpl()
    }

    interface DslBuilder {
        var items: List<CitySummary>?
        var nextToken: String?
        fun build(): ListCitiesOutput
    }

    private class BuilderImpl : DslBuilder {
        override var items: List<CitySummary>? = null
        override var nextToken: String? = null

        override fun build(): ListCitiesOutput = ListCitiesOutput(this)
    }
}
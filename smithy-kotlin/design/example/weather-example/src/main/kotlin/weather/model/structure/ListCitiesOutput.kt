package weather.model.structure

class ListCitiesOutput private constructor(builder: BuilderImpl) {
    val items: List<CitySummary>? = builder.items
    val nextToken: String? = builder.nextToken

    companion object {
        operator fun invoke(block: DslBuilder.() -> Unit) = BuilderImpl().apply(block).build()
    }

    interface Builder {
        fun build(): ListCitiesOutput
        // TODO - Java fill in Java builder
    }

    interface DslBuilder {
        var items: List<CitySummary>?
        var nextToken: String?
    }

    private class BuilderImpl : Builder, DslBuilder {
        override var items: List<CitySummary>? = null
        override var nextToken: String? = null

        override fun build(): ListCitiesOutput = ListCitiesOutput(this)
    }
}
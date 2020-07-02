package weather.model.structure

class GetForecastOutput private constructor(builder: BuilderImpl) {
    val chanceOfRain: Float? = builder.chanceOfRain

    companion object {
        operator fun invoke(block: DslBuilder.() -> Unit) = BuilderImpl().apply(block).build()
        fun dslBuilder(): DslBuilder = BuilderImpl()
    }

    interface DslBuilder {
        var chanceOfRain: Float?
        fun build(): GetForecastOutput
    }

    private class BuilderImpl : DslBuilder {
        override var chanceOfRain: Float? = null

        override fun build(): GetForecastOutput = GetForecastOutput(this)
    }
}
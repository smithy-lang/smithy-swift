package weather.model.structure

class GetForecastOutput private constructor(builder: BuilderImpl) {

    val chanceOfRain: Float? = builder.chanceOfRain

    companion object {
        operator fun invoke(block: DslBuilder.() -> Unit) = BuilderImpl().apply(block).build()
    }

    interface Builder {
        fun build(): GetForecastOutput
        // TODO - Java fill in Java builder
    }

    interface DslBuilder {
        var chanceOfRain: Float?
    }

    private class BuilderImpl : Builder, DslBuilder {
        override var chanceOfRain: Float? = null

        override fun build(): GetForecastOutput = GetForecastOutput(this)
    }
}
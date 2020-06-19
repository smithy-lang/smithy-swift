package weather.model.structure

/**
 * The input used to get a city.
 */
class GetCityInput private constructor(builder: BuilderImpl) {
    val cityId: String? = builder.cityId

    companion object {
        operator fun invoke(block: DslBuilder.() -> Unit) = BuilderImpl().apply(block).build()
    }

    interface Builder {
        fun build(): GetCityInput
        // TODO - Java fill in Java builder
    }

    interface DslBuilder {
        var cityId: String?
    }

    private class BuilderImpl : Builder, DslBuilder {
        override var cityId: String? = null

        override fun build(): GetCityInput = GetCityInput(this)
    }
}
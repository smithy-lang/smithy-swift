package weather.model.structure

/**
 * The input used to get a city.
 */
class GetCityInput private constructor(builder: BuilderImpl) {
    val cityId: String? = builder.cityId

    companion object {
        operator fun invoke(block: DslBuilder.() -> Unit) = BuilderImpl().apply(block).build()
        fun dslBuilder(): DslBuilder = BuilderImpl()
    }

    interface DslBuilder {
        var cityId: String?
        fun build(): GetCityInput
    }

    private class BuilderImpl : DslBuilder {
        override var cityId: String? = null

        override fun build(): GetCityInput = GetCityInput(this)
    }
}
package weather.model.structure

class GetCityImageInput private constructor(builder: BuilderImpl) {
    val cityId: String? = builder.cityId

    companion object {
        operator fun invoke(block: DslBuilder.() -> Unit) = BuilderImpl().apply(block).build()
    }

    interface Builder {
        fun build(): GetCityImageInput
        // TODO - Java fill in Java builder
    }

    interface DslBuilder {
        var cityId: String?
    }

    private class BuilderImpl : Builder, DslBuilder {
        override var cityId: String? = null

        override fun build(): GetCityImageInput = GetCityImageInput(this)
    }
}
// Code generated by smithy-kotlin-codegen. DO NOT EDIT!

package weather.model.structure

class GetForecastInput private constructor(builder: BuilderImpl) {

    val cityId: String? = builder.cityId

    companion object {
        operator fun invoke(block: DslBuilder.() -> Unit) = BuilderImpl().apply(block).build()
        fun dslBuilder(): DslBuilder = BuilderImpl()
    }

    interface DslBuilder {
        var cityId: String?
        fun build(): GetForecastInput
    }

    private class BuilderImpl : DslBuilder {
        override var cityId: String? = null

        override fun build(): GetForecastInput = GetForecastInput(this)
    }
}

package weather.model.structure

import software.aws.clientrt.serde.Deserializer
import software.aws.clientrt.serde.SdkFieldDescriptor
import software.aws.clientrt.serde.SdkObjectDescriptor
import software.aws.clientrt.serde.deserializeStruct

class CitySummary private constructor(builder: BuilderImpl) {
    val case: String? = builder.case
    val cityId: String? = builder.cityId
    val name: String? = builder.name
    val number: String? = builder.number

    companion object {
        operator fun invoke(block: DslBuilder.() -> Unit) = BuilderImpl().apply(block).build()
        fun dslBuilder(): DslBuilder = BuilderImpl()
    }

    interface DslBuilder {
        var case: String?
        var cityId: String?
        var name: String?
        var number: String?

        fun build(): CitySummary
    }

    private class BuilderImpl : DslBuilder {
        override var case: String? = null
        override var cityId: String? = null
        override var name: String? = null
        override var number: String? = null

        override fun build(): CitySummary = CitySummary(this)
    }
}

class CitySummaryDeserializer {
    companion object {
        private val CASE_FIELD_DESCRIPTOR = SdkFieldDescriptor("case")
        private val CITY_ID_FIELD_DESCRIPTOR = SdkFieldDescriptor("cityId")
        private val NAME_FIELD_DESCRIPTOR = SdkFieldDescriptor("name")
        private val NUMBER_FIELD_DESCRIPTOR = SdkFieldDescriptor("number")

        private val OBJ_DESCRIPTOR = SdkObjectDescriptor.build {
            field(CASE_FIELD_DESCRIPTOR)
            field(CITY_ID_FIELD_DESCRIPTOR)
            field(NAME_FIELD_DESCRIPTOR)
            field(NUMBER_FIELD_DESCRIPTOR)
        }

        fun deserialize(deserializer: Deserializer): Any {
            val citySummaryBuilder = CitySummary.dslBuilder()
            deserializer.deserializeStruct(null) {
                loop@ while (true) {
                    when (nextField(OBJ_DESCRIPTOR)) {
                        CASE_FIELD_DESCRIPTOR.index -> citySummaryBuilder.case = deserializeString()
                        CITY_ID_FIELD_DESCRIPTOR.index -> citySummaryBuilder.cityId = deserializeString()
                        NAME_FIELD_DESCRIPTOR.index -> citySummaryBuilder.name = deserializeString()
                        NUMBER_FIELD_DESCRIPTOR.index -> citySummaryBuilder.name = deserializeString()

                        Deserializer.FieldIterator.EXHAUSTED -> break@loop
                        else -> skipValue()
                    }
                }
            }

            return citySummaryBuilder.build()
        }
    }
}
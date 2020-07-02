package weather.model.structure

import software.aws.clientrt.serde.Deserializer
import software.aws.clientrt.serde.SdkFieldDescriptor
import software.aws.clientrt.serde.SdkObjectDescriptor
import software.aws.clientrt.serde.deserializeStruct

class CityCoordinates private constructor(builder: BuilderImpl) {
    val latitude: Float? = builder.latitude
    val longitude: Float? = builder.longitude

    companion object {
        operator fun invoke(block: DslBuilder.() -> Unit) = BuilderImpl().apply(block).build()
        fun dslBuilder(): DslBuilder = BuilderImpl()
    }

    interface Builder {
        fun build(): CityCoordinates
        // TODO - Java fill in Java builder
    }

    interface DslBuilder {
        var latitude: Float?
        var longitude: Float?

        fun build(): CityCoordinates
    }

    private class BuilderImpl : Builder, DslBuilder {
        override var latitude: Float? = null
        override var longitude: Float? = null

        override fun build(): CityCoordinates = CityCoordinates(this)
    }
}

class CityCoordinatesDeserializer {
    companion object {
        private val LATITUDE_FIELD_DESCRIPTOR = SdkFieldDescriptor("latitude")
        private val LONGITUDE_FIELD_DESCRIPTOR = SdkFieldDescriptor("longitude")

        private val OBJ_DESCRIPTOR = SdkObjectDescriptor.build {
            field(LATITUDE_FIELD_DESCRIPTOR)
            field(LONGITUDE_FIELD_DESCRIPTOR)
        }

        fun deserialize(deserializer: Deserializer): Any {
            val cityCoordinatesBuilder = CityCoordinates.dslBuilder()
            deserializer.deserializeStruct(null) {
                loop@ while (true) {
                    when (nextField(OBJ_DESCRIPTOR)) {
                        LATITUDE_FIELD_DESCRIPTOR.index -> cityCoordinatesBuilder.latitude = deserializeFloat()
                        LONGITUDE_FIELD_DESCRIPTOR.index -> cityCoordinatesBuilder.longitude = deserializeFloat()

                        Deserializer.FieldIterator.EXHAUSTED -> break@loop
                        else -> skipValue()
                    }
                }
            }

            return cityCoordinatesBuilder.build()
        }
    }
}
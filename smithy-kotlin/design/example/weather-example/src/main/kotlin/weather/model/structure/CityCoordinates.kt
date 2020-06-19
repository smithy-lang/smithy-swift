
package weather.model.structure

import com.amazonaws.service.runtime.HttpDeserialize
import software.aws.clientrt.content.ByteStream
import software.aws.clientrt.http.response.HttpResponse
import software.aws.clientrt.serde.Deserializer
import software.aws.clientrt.serde.SdkFieldDescriptor
import software.aws.clientrt.serde.SdkObjectDescriptor
import software.aws.clientrt.serde.deserializeStruct

class CityCoordinates private constructor(builder: BuilderImpl) {
    val latitude: Float? = builder.latitude
    val longitude: Float? = builder.longitude

    companion object {
        operator fun invoke(block: DslBuilder.() -> Unit) = BuilderImpl().apply(block).build()
    }

    interface Builder {
        fun build(): CityCoordinates
        // TODO - Java fill in Java builder
    }

    interface DslBuilder {
        var latitude: Float?
        var longitude: Float?
    }

    private class BuilderImpl : Builder, DslBuilder {
        override var latitude: Float? = null
        override var longitude: Float? = null

        override fun build(): CityCoordinates = CityCoordinates(this)
    }
}

class CityCoordinatesDeserializer : HttpDeserialize {
    companion object {
        private val LATITUDE_FIELD_DESCRIPTOR = SdkFieldDescriptor("latitude")
        private val LONGITUDE_FIELD_DESCRIPTOR = SdkFieldDescriptor("longitude")

        private val OBJ_DESCRIPTOR = SdkObjectDescriptor.build {
            field(LATITUDE_FIELD_DESCRIPTOR)
            field(LONGITUDE_FIELD_DESCRIPTOR)
        }
    }

    override suspend fun deserialize(response: HttpResponse, deserializer: Deserializer): CityCoordinates {
        var parsedLatitude: Float? = null
        var parsedlongitude: Float? = null

        deserializer.deserializeStruct(null) {
            loop@while(true) {
                when(nextField(OBJ_DESCRIPTOR)) {
                    LATITUDE_FIELD_DESCRIPTOR.index -> parsedLatitude = deserializeFloat()
                    LONGITUDE_FIELD_DESCRIPTOR.index -> parsedlongitude = deserializeFloat()

                    Deserializer.FieldIterator.EXHAUSTED -> break@loop
                    else -> skipValue()
                }
            }
        }

        return CityCoordinates {
            latitude = parsedLatitude
            longitude = parsedlongitude
        }
    }
}
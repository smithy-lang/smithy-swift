package weather.model.structure

import com.amazonaws.service.runtime.HttpDeserialize
import kotlinx.coroutines.runBlocking
import software.aws.clientrt.http.response.HttpResponse
import software.aws.clientrt.serde.Deserializer
import software.aws.clientrt.serde.SdkFieldDescriptor
import software.aws.clientrt.serde.SdkObjectDescriptor
import software.aws.clientrt.serde.deserializeStruct

class GetCityOutput private constructor(builder: BuilderImpl) {

    val city: CitySummary? = builder.city
    val coordinates: CityCoordinates? = builder.coordinates
    val name: String? = builder.name

    companion object {
        operator fun invoke(block: DslBuilder.() -> Unit) = BuilderImpl().apply(block).build()
    }

    interface Builder {
        fun build(): GetCityOutput
        // TODO - Java fill in Java builder
    }

    interface DslBuilder {
        var city: CitySummary?
        var coordinates: CityCoordinates?
        var name: String?
    }

    private class BuilderImpl : Builder, DslBuilder {
        override var city: CitySummary? = null
        override var coordinates: CityCoordinates? = null
        override var name: String? = null

        override fun build(): GetCityOutput = GetCityOutput(this)
    }
}

class GetCityOutputDeserializer : HttpDeserialize {
    companion object {
        private val CITY_FIELD_DESCRIPTOR = SdkFieldDescriptor("city")
        private val COORDINATES_FIELD_DESCRIPTOR = SdkFieldDescriptor("coordinates")
        private val NAME_FIELD_DESCRIPTOR = SdkFieldDescriptor("name")

        private val OBJ_DESCRIPTOR = SdkObjectDescriptor.build {
            field(CITY_FIELD_DESCRIPTOR)
            field(COORDINATES_FIELD_DESCRIPTOR)
            field(NAME_FIELD_DESCRIPTOR)
        }
    }

    override suspend fun deserialize(response: HttpResponse, deserializer: Deserializer): Any {
        var parsedCity: CitySummary? = null
        var parsedCoordinates: CityCoordinates? = null
        var parsedName: String? = null

        deserializer.deserializeStruct(null) {
            loop@ while (true) {
                when (nextField(OBJ_DESCRIPTOR)) {
                    CITY_FIELD_DESCRIPTOR.index -> parsedCity =
                        runBlocking { CitySummaryDeserializer().deserialize(response, deserializer) }
                    COORDINATES_FIELD_DESCRIPTOR.index -> parsedCoordinates =
                        runBlocking { CityCoordinatesDeserializer().deserialize(response, deserializer) }
                    NAME_FIELD_DESCRIPTOR.index -> parsedName = deserializeString()
                    Deserializer.FieldIterator.EXHAUSTED -> break@loop
                    else -> skipValue()
                }
            }
        }

        return GetCityOutput {
            city = parsedCity
            coordinates = parsedCoordinates
            name = parsedName
        }
    }
}
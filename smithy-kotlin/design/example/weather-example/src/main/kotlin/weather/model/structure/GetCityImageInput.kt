package weather.model.structure

import software.aws.clientrt.http.HttpMethod
import software.aws.clientrt.http.content.ByteArrayContent
import software.aws.clientrt.http.feature.HttpSerialize
import software.aws.clientrt.http.feature.SerializationProvider
import software.aws.clientrt.http.request.HttpRequestBuilder
import software.aws.clientrt.http.request.url
import software.aws.clientrt.serde.SdkFieldDescriptor
import software.aws.clientrt.serde.serializeStruct

class GetCityImageInput private constructor(builder: BuilderImpl) {
    val cityId: String? = builder.cityId

    companion object {
        operator fun invoke(block: DslBuilder.() -> Unit) = BuilderImpl().apply(block).build()
        fun dslBuilder(): DslBuilder = BuilderImpl()
    }

    interface DslBuilder {
        var cityId: String?
        fun build(): GetCityImageInput
    }

    private class BuilderImpl : DslBuilder {
        override var cityId: String? = null

        override fun build(): GetCityImageInput = GetCityImageInput(this)
    }
}

class GetCityImageInputSerializer(private val input: GetCityImageInput) : HttpSerialize {
    companion object {
        private val CITY_ID_FIELD_DESCRIPTOR = SdkFieldDescriptor("cityId")
    }

    override suspend fun serialize(builder: HttpRequestBuilder, provider: SerializationProvider) {
        val serializer = provider()
        serializer.serializeStruct {
            input.cityId?.let { field(CITY_ID_FIELD_DESCRIPTOR, it) }
        }

        builder.apply {
            url { this.path = "/cities/${input.cityId}" }
            method = HttpMethod.GET
            body = ByteArrayContent(serializer.toByteArray())
        }
    }
}
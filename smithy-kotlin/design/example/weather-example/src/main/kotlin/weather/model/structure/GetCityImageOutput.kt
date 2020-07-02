package weather.model.structure

import software.aws.clientrt.content.ByteStream
import software.aws.clientrt.http.feature.DeserializationProvider
import software.aws.clientrt.http.feature.HttpDeserialize
import software.aws.clientrt.http.response.HttpResponse
import software.aws.clientrt.http.toByteStream

// @streaming
// @httpPayload
class GetCityImageOutput private constructor(builder: BuilderImpl) {
    // @mediaType("image/jpeg")
    val image: ByteStream? = builder.image

    companion object {
        operator fun invoke(block: DslBuilder.() -> Unit) = BuilderImpl().apply(block).build()
    }

    interface DslBuilder {
        var image: ByteStream?
        fun build(): GetCityImageOutput
    }

    private class BuilderImpl : DslBuilder {
        override var image: ByteStream? = null

        override fun build(): GetCityImageOutput = GetCityImageOutput(this)
    }
}

class GetCityImageOutputDeserializer : HttpDeserialize {
    override suspend fun deserialize(response: HttpResponse, provider: DeserializationProvider): Any =
        GetCityImageOutput { image = response.body.toByteStream() ?: throw RuntimeException("Unable to create ByteStream from response.") }
}

package weather.model.structure

import com.amazonaws.service.runtime.HttpDeserialize
import com.amazonaws.service.runtime.toByteStream
import software.aws.clientrt.content.ByteStream
import software.aws.clientrt.http.response.HttpResponse
import software.aws.clientrt.serde.Deserializer
import software.aws.clientrt.serde.SdkFieldDescriptor
import software.aws.clientrt.serde.SdkObjectDescriptor
import software.aws.clientrt.serde.deserializeStruct

// @streaming
// @httpPayload
class GetCityImageOutput private constructor(builder: BuilderImpl) {
    // @mediaType("image/jpeg")
    val image: ByteStream? = builder.image

    companion object {
        operator fun invoke(block: DslBuilder.() -> Unit) = BuilderImpl().apply(block).build()
    }

    interface Builder {
        fun build(): GetCityImageOutput
        // TODO - Java fill in Java builder
    }

    interface DslBuilder {
        var image: ByteStream?
    }

    private class BuilderImpl : Builder, DslBuilder {
        override var image: ByteStream? = null

        override fun build(): GetCityImageOutput = GetCityImageOutput(this)
    }
}

class GetCityImageOutputDeserializer : HttpDeserialize {
    override suspend fun deserialize(response: HttpResponse, deserializer: Deserializer): GetCityImageOutput =
        GetCityImageOutput { image = response.body.toByteStream() ?: throw RuntimeException("Unable to create ByteStream from response.") }
}

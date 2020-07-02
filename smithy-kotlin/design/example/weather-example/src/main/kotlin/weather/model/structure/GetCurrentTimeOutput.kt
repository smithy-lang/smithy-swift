package weather.model.structure

import software.aws.clientrt.ClientException
import software.aws.clientrt.http.feature.DeserializationProvider
import software.aws.clientrt.http.feature.HttpDeserialize
import software.aws.clientrt.http.readAll
import software.aws.clientrt.http.response.HttpResponse
import software.aws.clientrt.serde.Deserializer
import software.aws.clientrt.serde.SdkFieldDescriptor
import software.aws.clientrt.serde.SdkObjectDescriptor
import software.aws.clientrt.serde.deserializeStruct

class GetCurrentTimeOutput private constructor(builder: BuilderImpl) {
    val time: Long? = builder.time

    companion object {
        operator fun invoke(block: DslBuilder.() -> Unit) = BuilderImpl().apply(block).build()
        fun dslBuilder(): DslBuilder = BuilderImpl()
    }

    interface DslBuilder {
        var time: Long?

        fun build(): GetCurrentTimeOutput
    }

    private class BuilderImpl : DslBuilder {
        override var time: Long? = null

        override fun build(): GetCurrentTimeOutput = GetCurrentTimeOutput(this)
    }
}

class GetCurrentTimeOutputDeserializer : HttpDeserialize {
    companion object {
        private val TIME_FIELD_DESCRIPTOR = SdkFieldDescriptor("time")

        private val OBJ_DESCRIPTOR = SdkObjectDescriptor.build {
            field(TIME_FIELD_DESCRIPTOR)
        }
    }

    override suspend fun deserialize(response: HttpResponse, provider: DeserializationProvider): Any {
        val getCurrentTimeOutputBuilder = GetCurrentTimeOutput.dslBuilder()
        val payload = response.body.readAll() ?: throw ClientException("expected a response payload")
        val deserializer = provider(payload)

        deserializer.deserializeStruct(null) {
            loop@while(true) {
                when(nextField(OBJ_DESCRIPTOR)) {
                    TIME_FIELD_DESCRIPTOR.index -> getCurrentTimeOutputBuilder.time = deserializeLong()
                    Deserializer.FieldIterator.EXHAUSTED -> break@loop
                    else -> skipValue()
                }
            }
        }

        return getCurrentTimeOutputBuilder.build()
    }
}
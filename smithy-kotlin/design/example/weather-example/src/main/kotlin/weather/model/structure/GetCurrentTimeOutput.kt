package weather.model.structure

import com.amazonaws.service.runtime.HttpDeserialize
import software.aws.clientrt.http.response.HttpResponse
import software.aws.clientrt.serde.Deserializer
import software.aws.clientrt.serde.SdkFieldDescriptor
import software.aws.clientrt.serde.SdkObjectDescriptor
import software.aws.clientrt.serde.deserializeStruct

class GetCurrentTimeOutput private constructor(builder: BuilderImpl) {

    val time: Long? = builder.time

    companion object {
        operator fun invoke(block: DslBuilder.() -> Unit) = BuilderImpl().apply(block).build()
    }

    interface Builder {
        fun build(): GetCurrentTimeOutput
        // TODO - Java fill in Java builder
    }

    interface DslBuilder {
        var time: Long?
    }

    private class BuilderImpl : Builder, DslBuilder {
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

    override suspend fun deserialize(response: HttpResponse, deserializer: Deserializer): GetCurrentTimeOutput {
        var parsedTime: Long? = null

        deserializer.deserializeStruct(null) {
            loop@while(true) {
                when(nextField(OBJ_DESCRIPTOR)) {
                    TIME_FIELD_DESCRIPTOR.index -> parsedTime = deserializeLong()
                    Deserializer.FieldIterator.EXHAUSTED -> break@loop
                    else -> skipValue()
                }
            }
        }

        return GetCurrentTimeOutput {
            time = parsedTime ?: throw RuntimeException("Deserialization failed, missing field `time`.")
        }
    }
}
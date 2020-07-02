package weather.client

import software.aws.clientrt.SdkClient
import software.aws.clientrt.http.HttpMethod
import weather.model.structure.*
import java.io.Closeable

interface WeatherClient : SdkClient {
    override val serviceName: String
        get() = "weather-example"

    suspend fun getCurrentTime(): GetCurrentTimeOutput

    suspend fun getCity(input: GetCityInput): GetCityOutput

    suspend fun getCityImage(input: GetCityImageInput): GetCityImageOutput

}

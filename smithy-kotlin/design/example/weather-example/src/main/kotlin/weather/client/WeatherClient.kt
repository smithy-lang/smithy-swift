package weather.client

import software.aws.clientrt.SdkClient
import software.aws.clientrt.http.HttpMethod
import weather.model.structure.*

interface WeatherClient : SdkClient {
    override val serviceName: String
        get() = "weather-example"

    suspend fun getCurrentTime(path: String, httpMethod: HttpMethod): GetCurrentTimeOutput

    suspend fun getCity(input: GetCityInput, path: String, httpMethod: HttpMethod): GetCityOutput

    suspend fun getCityImage(input: GetCityImageInput, path: String, httpMethod: HttpMethod): GetCityImageOutput
}

package weather.client

import software.aws.clientrt.SdkClient
import software.aws.clientrt.http.HttpMethod
import weather.model.structure.*
import java.io.Closeable

interface WeatherClient : SdkClient {
    override val serviceName: String
        get() = "weather-example"

    // Operation:
    // @readonly
    // @http(method: "GET", uri: "/current-time")
    suspend fun getCurrentTime(): GetCurrentTimeOutput

    // Operation: GetCity
    // TODO: model errors
    // @readonly
    // @http(method: "GET", uri: "/cities/{cityId}")
    suspend fun getCity(input: GetCityInput): GetCityOutput

    // Operation: GetCityImage
    // @readonly
    // @http(method: "GET", uri: "/cities/{cityId}/image")
    // TODO: model errors
    suspend fun getCityImage(input: GetCityImageInput): GetCityImageOutput

    // Operation: ListCities
    // @readonly
    // @paginated(items: "items")
    // @http(method: "GET", uri: "/cities")
    suspend fun listCities(input: ListCitiesInput): ListCitiesOutput

    //Operation: GetForecast
    // @http(method: "GET", uri: "/cities/{cityId}/forecast")
    suspend fun getForecast(input: GetForecastInput): GetForecastOutput
}

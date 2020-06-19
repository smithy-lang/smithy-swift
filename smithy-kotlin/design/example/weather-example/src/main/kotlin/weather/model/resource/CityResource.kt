package weather.model.resource

import com.amazonaws.service.runtime.weather.client.WeatherClient
import software.aws.clientrt.http.HttpMethod
import weather.client.DefaultWeatherClient
import weather.model.structure.GetCityInput
import weather.model.structure.GetCityOutput
import weather.model.structure.ListCitiesInput
import weather.model.structure.ListCitiesOutput

class CityResource(private val client: WeatherClient) {

    // Operation: GetCity
    // TODO: model errors
    // @readonly
    // @http(method: "GET", uri: "/cities/{cityId}")
    suspend fun getCity(input: GetCityInput): GetCityOutput = client.getCity(input, "/cities/{cityId}", HttpMethod.GET)

    // Operation: ListCities
    // @readonly
    // @paginated(items: "items")
    // @http(method: "GET", uri: "/cities")
    fun listCities(input: ListCitiesInput): ListCitiesOutput = TODO("implement")
}
package weather.model.resource

import weather.client.WeatherClient
import software.aws.clientrt.http.HttpMethod
import weather.model.structure.GetCityImageInput
import weather.model.structure.GetCityImageOutput

class CityImageResource(private val client: WeatherClient) {

    // @readonly
    // @http(method: "GET", uri: "/cities/{cityId}/image")
    // TODO: model errors
    suspend fun getCityImage(input: GetCityImageInput): GetCityImageOutput = client.getCityImage(input)
}
package weather.model.service

import weather.client.WeatherClient
import software.aws.clientrt.http.HttpMethod
import weather.model.resource.CityImageResource
import weather.model.resource.CityResource
import weather.model.structure.GetCurrentTimeOutput

// @protocols([{name: "aws.rest-json-1.1"}])
class WeatherService(private val client: WeatherClient) {

    // Resources
    val cityResource: CityResource = CityResource(client)

    val cityImageResource: CityImageResource = CityImageResource(client)

    // Operations

    // Operation:
    // @readonly
    // @http(method: "GET", uri: "/current-time")
    suspend fun getCurrentTime(): GetCurrentTimeOutput = client.getCurrentTime()
}
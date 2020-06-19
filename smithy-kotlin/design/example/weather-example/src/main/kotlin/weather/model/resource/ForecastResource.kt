package weather.model.resource

import weather.model.structure.GetForecastInput
import weather.model.structure.GetForecastOutput

class ForecastResource {

    //Operation: GetForecast
    // @http(method: "GET", uri: "/cities/{cityId}/forecast")
    fun getForecast(input: GetForecastInput): GetForecastOutput = TODO("implement")
}
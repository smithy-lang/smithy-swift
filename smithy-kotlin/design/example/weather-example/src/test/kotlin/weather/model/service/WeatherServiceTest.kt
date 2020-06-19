package weather.model.service

import kotlinx.coroutines.runBlocking
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import weather.client.DefaultWeatherClient
import weather.model.structure.GetCityInput

class WeatherServiceTest {

    @Test
    fun `can call getCurrentTime and return non-null value`() {
        val unit = WeatherService(DefaultWeatherClient())

        runBlocking {
            val time = unit.getCurrentTime()

            Assertions.assertNotNull(time)
        }
    }

    @Test
    fun `can call City resource from service`() {
        val unit = WeatherService(DefaultWeatherClient())

        runBlocking {
            val cityOutput = unit.cityResource.getCity(GetCityInput{ cityId = "testcityid" })

            //TODO: handle error response

            Assertions.assertNotNull(cityOutput)
            Assertions.assertNotNull(cityOutput.city!!.cityId)
        }
    }
}
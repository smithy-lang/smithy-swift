package weather.model.resource

import kotlinx.coroutines.runBlocking
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import software.aws.clientrt.content.toByteArray
import weather.client.DefaultWeatherClient
import weather.model.service.WeatherService
import weather.model.structure.GetCityImageInput

class CityImageResourceTest {

    @Test
    fun `can retrieve image`() {
        val unit = WeatherService(DefaultWeatherClient())

        runBlocking {
            val input = GetCityImageInput {
                cityId = "testcityid"
            }

            val cityImageResourceOutput = unit.cityImageResource.getCityImage(input = input)

            Assertions.assertNotNull(cityImageResourceOutput.image)
            //TODO: handle error response

            val bytes = cityImageResourceOutput.image?.toByteArray()

            Assertions.assertNotNull(bytes)
            Assertions.assertTrue(bytes!!.isNotEmpty())
        }
    }
}
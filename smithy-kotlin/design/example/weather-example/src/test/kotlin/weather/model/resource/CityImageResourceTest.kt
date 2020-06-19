package weather.model.resource

import com.amazonaws.service.runtime.toByteArray
import kotlinx.coroutines.runBlocking
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
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

            // TODO: Determine why this fails.  I can see that 19 bytes are returned in KtorEngine in the response but
            // somehow the bytes are not making it back to the response object.
            Assertions.assertTrue(bytes!!.isNotEmpty())
        }
    }
}
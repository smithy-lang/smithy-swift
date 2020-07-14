
package weather.client

import kotlinx.coroutines.runBlocking
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import software.aws.clientrt.content.toByteArray
import weather.model.structure.GetCityImageInput
import weather.model.structure.GetCityInput
import java.time.LocalDate
import java.time.Month

class DefaultWeatherClientTest {

    @Test
    fun `can call the getCurrentTime operation on the service`() {
        val unit: WeatherClient = DefaultWeatherClient()

        val response = runBlocking { unit.getCurrentTime() }

        Assertions.assertNotNull(response)
        Assertions.assertTrue(response.time!! > LocalDate.of(2020, Month.JANUARY, 1).toEpochDay())

    }


    @Test
    fun `can call getCurrentTime and return non-null value`() {
        val unit: WeatherClient = DefaultWeatherClient()

        runBlocking {
            val time = unit.getCurrentTime()

            Assertions.assertNotNull(time)
        }
    }

    @Test
    fun `can call City resource from service`() {
        val unit: WeatherClient = DefaultWeatherClient()

        runBlocking {
            val cityOutput = unit.getCity(GetCityInput{ cityId = "testcityid" })

            //TODO: handle error response

            Assertions.assertNotNull(cityOutput)
            Assertions.assertNotNull(cityOutput.city!!.cityId)
        }
    }


    @Test
    fun `can retrieve image`() {
        val unit: WeatherClient = DefaultWeatherClient()

        runBlocking {
            val input = GetCityImageInput {
                cityId = "testcityid"
            }

            val cityImageResourceOutput = unit.getCityImage(input = input)

            Assertions.assertNotNull(cityImageResourceOutput.image)
            //TODO: handle error response

            val bytes = cityImageResourceOutput.image?.toByteArray()

            Assertions.assertNotNull(bytes)
            Assertions.assertTrue(bytes!!.isNotEmpty())
        }
    }

    @Test
    fun `can construct a city input and print its state`() {
        val gci = GetCityInput { cityId = "city1234" }

        println(gci.cityId)

        Assertions.assertTrue(gci.cityId == "city1234")
    }
}
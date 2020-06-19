
package weather.client

import kotlinx.coroutines.runBlocking
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import weather.model.service.WeatherService
import java.time.LocalDate
import java.time.Month

class DefaultWeatherClientTest {

    @Test
    fun `can call the getCurrentTime operation on the service`() {
        val unit = WeatherService(DefaultWeatherClient())

        runBlocking {
            val response = unit.getCurrentTime()

            Assertions.assertNotNull(response)
            Assertions.assertTrue(response.time!! > LocalDate.of(2020, Month.JANUARY, 1).toEpochDay())
        }
    }
}
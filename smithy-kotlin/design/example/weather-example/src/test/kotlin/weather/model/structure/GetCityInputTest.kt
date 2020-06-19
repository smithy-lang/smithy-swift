package weather.model.structure

import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test

class GetCityInputTest {

    @Test
    fun `can construct a city input and print its state`() {
        val gci = GetCityInput { cityId = "city1234" }

        println(gci.cityId)

        Assertions.assertTrue(gci.cityId == "city1234")
    }
}

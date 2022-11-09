import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.utils.toLowerCamelCase
import software.amazon.smithy.swift.codegen.utils.toUpperCamelCase

class CaseUtilsTests {
    @Test
    fun `it should convert to camel case when only first letter upper case`() {
        val input = "FooBar"
        val expected = "fooBar"
        val actual = input.toLowerCamelCase()
        assertEquals(expected, actual)
    }

    @Test
    fun `it should convert to camel case when contiguous letters upper case`() {
        val input = "FOOBar"
        val expected = "fooBar"
        val actual = input.toLowerCamelCase()
        assertEquals(expected, actual)
    }

    @Test
    fun `it should convert to upper case when only first is lower case`() {
        val input = "fooBar"
        val expected = "FooBar"
        val actual = input.toUpperCamelCase()
        assertEquals(expected, actual)
    }

    @Test
    fun `it should convert to upper case when contiguous letters lower case`() {
        val input = "fOOBar"
        val expected = "FOOBar"
        val actual = input.toUpperCamelCase()
        assertEquals(expected, actual)
    }

    @Test
    fun `it should preserve underscore`() {
        val input = "Foo_Bar"
        val expected = "foo_Bar"
        val actual = input.toLowerCamelCase()
        assertEquals(expected, actual)
    }
}

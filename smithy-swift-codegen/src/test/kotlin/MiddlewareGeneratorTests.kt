import io.kotest.matchers.string.shouldContain
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.MiddlewareGenerator
import software.amazon.smithy.swift.codegen.SwiftWriter

class MiddlewareGeneratorTests {
    @Test
    fun `generates middleware structs`() {
        val writer = SwiftWriter("MockPackage")
        val generator = MiddlewareGenerator(writer, "Test", inputType = "String", outputType = "String") {
            it.write("print(\"this is a test\")")
        }
        generator.render()
        val contents = writer.toString()
        val expectedGeneratedStructure =
            """
            public struct TestMiddleware: Middleware {
                public var id: String = "Test"
            
                public func handle<H>(context: Context,
                              input: String,
                              next: H) -> Result<String, Error>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context
                {
                    print("this is a test")
                }
            
                public typealias MInput = String
                public typealias MOutput = String
                public typealias Context = HttpContext
            }
            """.trimIndent()
        contents.shouldContain(expectedGeneratedStructure)
    }
}
import io.kotest.matchers.string.shouldContain
import org.junit.jupiter.api.Test
import software.amazon.smithy.codegen.core.Symbol
import software.amazon.smithy.swift.codegen.Middleware
import software.amazon.smithy.swift.codegen.MiddlewareGenerator
import software.amazon.smithy.swift.codegen.OperationStep
import software.amazon.smithy.swift.codegen.SwiftTypes
import software.amazon.smithy.swift.codegen.SwiftWriter

class MiddlewareGeneratorTests {
    @Test
    fun `generates middleware structs`() {
        val writer = SwiftWriter("MockPackage")
        val testSymbol = Symbol.builder().name("Test").build()
        val mockMiddleware = MockMiddleware(writer, testSymbol)
        val generator = MiddlewareGenerator(writer, mockMiddleware)
        generator.generate()
        val contents = writer.toString()
        val expectedGeneratedStructure =
            """
            public struct TestMiddleware: ClientRuntime.Middleware {
                public let id: Swift.String = "TestMiddleware"
            
                let test: Swift.String
            
                public init() {}
            
                public func handle<H>(context: Context,
                              input: Swift.String,
                              next: H) -> Swift.Result<ClientRuntime.OperationOutput<Swift.String>, MError>
                where H: Handler,
                Self.MInput == H.Input,
                Self.MOutput == H.Output,
                Self.Context == H.Context,
                Self.MError == H.MiddlewareError
                {
                    print("this is a \(test)")
                    return next.handle(context: context, input: input)
                }
            
                public typealias MInput = Swift.String
                public typealias MOutput = ClientRuntime.OperationOutput<Swift.String>
                public typealias Context = ClientRuntime.HttpContext
                public typealias MError = ClientRuntime.SdkError<Swift.Error>
            }
            """.trimIndent()
        contents.shouldContain(expectedGeneratedStructure)
    }
}

class MockOperationStep(outputSymbol: Symbol, outputErrorSymbol: Symbol) : OperationStep(outputSymbol, outputErrorSymbol) {
    override val inputType: Symbol = SwiftTypes.String
}

class MockMiddleware(private val writer: SwiftWriter, symbol: Symbol) : Middleware(writer, symbol, MockOperationStep(SwiftTypes.String, SwiftTypes.Error)) {
    override val properties = mutableMapOf("test" to SwiftTypes.String)
    override fun generateMiddlewareClosure() {
        writer.write("print(\"this is a \\(test)\")")
    }

    override fun generateInit() {
        writer.write("public init() {}")
    }
}

import mocks.MockHttpResponseBindingErrorGenerator
import software.amazon.smithy.aws.traits.protocols.RestJson1Trait
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.integration.CodingKeysGenerator
import software.amazon.smithy.swift.codegen.integration.DefaultCodingKeysGenerator
import software.amazon.smithy.swift.codegen.integration.DefaultHttpProtocolCustomizations
import software.amazon.smithy.swift.codegen.integration.HttpBindingProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolTestGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestErrorGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestRequestGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestResponseGenerator
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.httpResponse.HttpResponseGeneratable
import software.amazon.smithy.swift.codegen.integration.httpResponse.HttpResponseGenerator

class MockRestJsonHttpProtocolCustomizations() : DefaultHttpProtocolCustomizations()
class MockHttpRestJsonProtocolGenerator : HttpBindingProtocolGenerator() {
    override val defaultContentType: String = "application/json"
    override val defaultTimestampFormat: TimestampFormatTrait.Format = TimestampFormatTrait.Format.DATE_TIME
    override val protocol: ShapeId = RestJson1Trait.ID
    override val httpProtocolClientGeneratorFactory = TestHttpProtocolClientGeneratorFactory()
    override val httpProtocolCustomizable = MockRestJsonHttpProtocolCustomizations()
    override val codingKeysGenerator: CodingKeysGenerator = DefaultCodingKeysGenerator()
    override val httpResponseGenerator: HttpResponseGeneratable = HttpResponseGenerator(
        unknownServiceErrorSymbol,
        serviceErrorProtocolSymbol,
        defaultTimestampFormat,
        MockHttpResponseBindingErrorGenerator()
    )

    override fun generateProtocolUnitTests(ctx: ProtocolGenerator.GenerationContext) {
        val requestTestBuilder = HttpProtocolUnitTestRequestGenerator.Builder()
        val responseTestBuilder = HttpProtocolUnitTestResponseGenerator.Builder()
        val errorTestBuilder = HttpProtocolUnitTestErrorGenerator.Builder()

        HttpProtocolTestGenerator(
            ctx,
            requestTestBuilder,
            responseTestBuilder,
            errorTestBuilder,
            httpProtocolCustomizable,
            HttpProtocolUnitTestGenerator.SerdeContext("JSONEncoder()", "JSONDecoder()", ".secondsSince1970")
        ).generateProtocolTests()
    }
}

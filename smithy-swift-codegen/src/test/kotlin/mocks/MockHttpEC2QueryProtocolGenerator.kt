package mocks

import TestHttpProtocolClientGeneratorFactory
import software.amazon.smithy.aws.traits.protocols.Ec2QueryTrait
import software.amazon.smithy.model.pattern.UriPattern
import software.amazon.smithy.model.shapes.MemberShape
import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.traits.HttpTrait
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.DefaultHttpProtocolCustomizations
import software.amazon.smithy.swift.codegen.integration.HttpBindingProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.HttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.HttpProtocolTestGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestErrorGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestRequestGenerator
import software.amazon.smithy.swift.codegen.integration.HttpProtocolUnitTestResponseGenerator
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.codingKeys.CodingKeysCustomizationEc2QueryName
import software.amazon.smithy.swift.codegen.integration.codingKeys.CodingKeysGenerator
import software.amazon.smithy.swift.codegen.integration.codingKeys.DefaultCodingKeysGenerator
import software.amazon.smithy.swift.codegen.integration.httpResponse.HttpResponseGeneratable
import software.amazon.smithy.swift.codegen.integration.httpResponse.HttpResponseGenerator
import software.amazon.smithy.swift.codegen.integration.protocols.core.StaticHttpBindingResolver
import software.amazon.smithy.swift.codegen.integration.serde.formurl.FormURLEncodeCustomizable
import software.amazon.smithy.swift.codegen.integration.serde.formurl.StructEncodeFormURLGenerator
import software.amazon.smithy.swift.codegen.integration.serde.formurl.trait.Ec2QueryNameTraitGenerator
import software.amazon.smithy.swift.codegen.integration.serde.xml.StructDecodeXMLGenerator
import software.amazon.smithy.swift.codegen.model.ShapeMetadata

class MockEC2QueryHttpProtocolCustomizations() : DefaultHttpProtocolCustomizations()

class MockEC2QueryHttpBindingResolver(
    private val context: ProtocolGenerator.GenerationContext,
) : StaticHttpBindingResolver(context, awsQueryHttpTrait) {

    companion object {
        private val awsQueryHttpTrait: HttpTrait = HttpTrait
            .builder()
            .code(200)
            .method("POST")
            .uri(UriPattern.parse("/"))
            .build()
    }
}

class MockEc2QueryFormURLEncodeCustomizations : FormURLEncodeCustomizable {
    override fun alwaysUsesFlattenedCollections(): Boolean {
        return true
    }
    override fun customNameTraitGenerator(shape: Shape, defaultName: String): String {
        return Ec2QueryNameTraitGenerator.construct(shape, defaultName).toString()
    }
}

class MockHttpEC2QueryProtocolGenerator : HttpBindingProtocolGenerator() {
    override val defaultContentType: String = "application/x-www-form-urlencoded"
    override val defaultTimestampFormat: TimestampFormatTrait.Format = TimestampFormatTrait.Format.DATE_TIME
    override val protocol: ShapeId = Ec2QueryTrait.ID
    override val httpProtocolClientGeneratorFactory = TestHttpProtocolClientGeneratorFactory()
    override val httpProtocolCustomizable = MockEC2QueryHttpProtocolCustomizations()
    override val codingKeysGenerator: CodingKeysGenerator = DefaultCodingKeysGenerator(CodingKeysCustomizationEc2QueryName())
    override val httpResponseGenerator: HttpResponseGeneratable = HttpResponseGenerator(
        unknownServiceErrorSymbol,
        serviceErrorProtocolSymbol,
        defaultTimestampFormat,
        MockHttpResponseBindingErrorGenerator()
    )
    override val shouldRenderDecodableBodyStructForInputShapes = false

    override fun renderStructEncode(
        ctx: ProtocolGenerator.GenerationContext,
        shapeContainingMembers: Shape,
        shapeMetadata: Map<ShapeMetadata, Any>,
        members: List<MemberShape>,
        writer: SwiftWriter,
        defaultTimestampFormat: TimestampFormatTrait.Format,
    ) {
        val customizations = MockEc2QueryFormURLEncodeCustomizations()
        val encodeGenerator = StructEncodeFormURLGenerator(ctx, customizations, shapeContainingMembers, shapeMetadata, members, writer, defaultTimestampFormat)
        encodeGenerator.render()
    }
    override fun renderStructDecode(
        ctx: ProtocolGenerator.GenerationContext,
        shapeMetadata: Map<ShapeMetadata, Any>,
        members: List<MemberShape>,
        writer: SwiftWriter,
        defaultTimestampFormat: TimestampFormatTrait.Format,
    ) {
        val decodeGenerator = StructDecodeXMLGenerator(ctx, members, mapOf(), writer, defaultTimestampFormat)
        decodeGenerator.render()
    }

    override fun getProtocolHttpBindingResolver(ctx: ProtocolGenerator.GenerationContext):
        HttpBindingResolver = MockEC2QueryHttpBindingResolver(ctx)

    override fun shouldRenderHttpBodyMiddleware(shape: Shape): Boolean {
        return true
    }

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
            HttpProtocolUnitTestGenerator.SerdeContext("FormURLEncoder()", "XMLDecoder()", ".secondsSince1970")
        ).generateProtocolTests()
    }
}

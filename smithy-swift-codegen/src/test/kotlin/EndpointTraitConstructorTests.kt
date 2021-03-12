
import org.junit.jupiter.api.Test
import software.amazon.smithy.model.traits.EndpointTrait
import software.amazon.smithy.swift.codegen.integration.EndpointTraitConstructor

class EndpointTraitConstructorTests {
    @Test
    fun `it constructs endpoint prefix with label`() {
        val model = """
            namespace com.test
            use aws.protocols#awsJson1_1
            @awsJson1_1
            service Example {
                version: "1.0.0",
                operations: [ GetStatus ]
            }
            @readonly
            @endpoint(hostPrefix: "{foo}.data.")
            @http(method: "POST", uri: "/status")
            operation GetStatus {
                input: GetStatusInput,
                output: GetStatusOutput
            }
            structure GetStatusInput {
                @required
                @hostLabel
                foo: String
            }
            
            structure GetStatusOutput {}
        """.asSmithyModel()

        val ctx = model.newTestContext("com.test#Example")

        ctx.generationCtx.service.operations.forEach {
            val operation = ctx.generationCtx.model.expectShape(it).asOperationShape().get()
            val inputShape = ctx.generationCtx.model.expectShape(operation.input.get())
            val endpointTrait = operation.getTrait(EndpointTrait::class.java).get()
            val endpointPrefix = EndpointTraitConstructor(endpointTrait, inputShape).construct()
            assert(endpointPrefix == "\\(input.foo).data.")
        }
    }
}

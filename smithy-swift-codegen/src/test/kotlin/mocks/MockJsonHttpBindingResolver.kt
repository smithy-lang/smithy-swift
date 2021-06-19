package mocks

import software.amazon.smithy.model.pattern.UriPattern
import software.amazon.smithy.model.traits.HttpTrait
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.protocols.core.StaticHttpBindingResolver

class MockJsonHttpBindingResolver(
    private val context: ProtocolGenerator.GenerationContext,
) : StaticHttpBindingResolver(context, awsJsonHttpTrait) {

    companion object {
        private val awsJsonHttpTrait: HttpTrait = HttpTrait
            .builder()
            .code(200)
            .method("POST")
            .uri(UriPattern.parse("/"))
            .build()
    }
}
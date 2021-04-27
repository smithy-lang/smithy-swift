package software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits

import software.amazon.smithy.model.traits.HttpResponseCodeTrait
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HttpBindingDescriptor
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class HttpResponseTraitResponseCode(
    val ctx: ProtocolGenerator.GenerationContext,
    val responseBindings: List<HttpBindingDescriptor>,
    val writer: SwiftWriter
) {
    fun render() {
        val responseCodeTraitMembers = responseBindings
            .filter { it.member.hasTrait(HttpResponseCodeTrait::class.java) }
            .toMutableSet()
        if (responseCodeTraitMembers.isNotEmpty()) {
            responseCodeTraitMembers.forEach {
                writer.write("self.${it.locationName.decapitalize()} = httpResponse.statusCode.rawValue")
            }
        }
    }
}

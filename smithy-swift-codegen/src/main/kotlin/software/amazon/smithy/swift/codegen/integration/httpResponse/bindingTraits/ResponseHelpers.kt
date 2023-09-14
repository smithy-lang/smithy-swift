package software.amazon.smithy.swift.codegen.integration.httpResponse.bindingTraits

import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.integration.HttpBindingDescriptor
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

fun writeInitialResponseMembers(ctx: ProtocolGenerator.GenerationContext, writer: SwiftWriter, initialResponseMembers: Set<HttpBindingDescriptor>) {
    initialResponseMembers.forEach { responseMember ->
        val responseMemberName = ctx.symbolProvider.toMemberName(responseMember.member)
        writer.apply {
            write("if let initialData = await messageDecoder.awaitInitialResponse() {")
            indent()
            write("let decoder = JSONDecoder()")
            write("do {")
            indent()
            write("let response = try decoder.decode([String: String].self, from: initialData)")
            write("self.$responseMemberName = response[\"$responseMemberName\"].map { value in KinesisClientTypes.Tag(value: value) }")
            dedent()
            write("} catch {")
            indent()
            write("print(\"Error decoding JSON: \\(error)\")")
            write("self.$responseMemberName = nil")
            dedent()
            write("}")
            dedent()
            write("} else {")
            indent()
            write("self.$responseMemberName = nil")
            dedent()
            write("}")
        }
    }
}

package software.amazon.smithy.swift.codegen

/*
Generates a swift middleware struct like the following:
public struct {name}Middleware: Middleware {

    public var id: String = {name}

    public func handle<H>(context: Context,
                          input: {inputType},
                          next: H) -> Result<{outputType}, Error>
    where H: Handler,
          Self.MInput == H.Input,
          Self.MOutput == H.Output,
          Self.Context == H.Context {
        //middleware code goes here i.e. call middleClosure to write that out
    }

    public typealias MInput = {inputType}
    public typealias MOutput = {outputType}
    public typealias Context = {contextType}
}
 */
class MiddlewareGenerator(
    private val writer: SwiftWriter,
    private val middleware: Middleware
) {
    fun generate() {

        writer.openBlock("public struct ${middleware.typeName}: ${middleware.getTypeInheritance()} {", "}") {
            writer.write("public let id: String = \"${middleware.typeName}\"")
            writer.write("")
            middleware.properties.forEach {
                val memberName = it.key
                val memberType = it.value
                writer.write("let $memberName: \$L", memberType)
                writer.write("")
            }
            middleware.generateInit()
            writer.write("")
            writer.write("public func handle<H>(context: Context,")
            writer.swiftFunctionParameterIndent {
                writer.write("  input: ${middleware.inputType.name},")
                writer.write("  next: H) -> Result<${middleware.outputType.name}, Error>")
            }
            writer.write("where H: Handler,")
            writer.write("Self.MInput == H.Input,")
            writer.write("Self.MOutput == H.Output,")
            writer.write("Self.Context == H.Context").openBlock("{", "}") {
                middleware.generateMiddlewareClosure()
                middleware.renderReturn()
            }
            writer.write("")
            writer.write("public typealias MInput = ${middleware.inputType.name}")
            writer.write("public typealias MOutput = ${middleware.outputType.name}")
            writer.write("public typealias Context = ${middleware.contextType.name}")
        }
    }
}

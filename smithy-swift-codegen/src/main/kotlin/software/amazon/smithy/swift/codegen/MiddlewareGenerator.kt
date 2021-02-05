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
    private val name: String,
    private val contextType: String = "HttpContext",
    private val inputType: String,
    private val outputType: String,
    private val middlewareClosure: (SwiftWriter) -> Unit
) {
    fun render() {
        writer.openBlock("public struct ${name}Middleware: Middleware {", "}") {
            writer.write("public var id: String = \"$name\"")
            writer.write("")
            writer.write("public func handle<H>(context: Context,")
            writer.swiftFunctionParameterIndent {
                writer.write("  input: $inputType,")
                writer.write("  next: H) -> Result<$outputType, Error>")
            }
            writer.write("where H: Handler,")
            writer.write("Self.MInput == H.Input,")
            writer.write("Self.MOutput == H.Output,")
            writer.write("Self.Context == H.Context").openBlock("{", "}") {
                middlewareClosure(writer)
            }
            writer.write("")
            writer.write("public typealias MInput = $inputType")
            writer.write("public typealias MOutput = $outputType")
            writer.write("public typealias Context = $contextType")
        }
    }
}

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

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
            writer.write("public let id: \$N = \"${middleware.id}\"", SwiftTypes.String)
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
                writer.write("  input: \$N,", middleware.inputType)
                writer.write("  next: H) async throws -> \$L", middleware.outputType)
            }
            writer.write("where H: Handler,")
            writer.write("Self.MInput == H.Input,")
            writer.write("Self.MOutput == H.Output,")
            writer.write("Self.Context == H.Context").openBlock("{", "}") {
                middleware.generateMiddlewareClosure()
                middleware.renderReturn()
            }
            writer.write("")
            writer.write("public typealias MInput = \$N", middleware.inputType)
            writer.write("public typealias MOutput = \$L", middleware.outputType)
            writer.write("public typealias Context = \$N", middleware.contextType)
        }

        middleware.renderExtensions()
    }
}

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.swift.codegen.swiftmodules.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SmithyTypes
import software.amazon.smithy.swift.codegen.swiftmodules.SwiftTypes

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

        val inheritance = middleware
            .typesToConformMiddlewareTo
            .map { writer.format("\$N", it) }
            .joinToString(", ")
        writer.openBlock("public struct \$L: \$L {", "}", middleware.typeName, inheritance) {
            writer.write("public let id: \$N = \$S", SwiftTypes.String, middleware.id)
            writer.write("")
            middleware.properties.forEach {
                val memberName = it.key
                val memberType = it.value
                writer.write("let $memberName: \$N", memberType)
                writer.write("")
            }
            middleware.generateInit()
            writer.write("")

            writer.write("public func handle<H>(context: \$N,", SmithyTypes.Context)
            writer.swiftFunctionParameterIndent {
                writer.write("  input: \$N,", middleware.inputType)
                writer.write("  next: H) async throws -> \$N", middleware.outputType)
            }
            writer.write("where H: \$N,", ClientRuntimeTypes.Middleware.Handler)
            writer.write("Self.MInput == H.Input,")
            writer.write("Self.MOutput == H.Output").openBlock("{", "}") {
                middleware.generateMiddlewareClosure()
                middleware.renderReturn()
            }
            writer.write("")
            writer.write("public typealias MInput = \$N", middleware.inputType)
            writer.write("public typealias MOutput = \$N", middleware.outputType)
        }

        middleware.renderExtensions()
    }
}

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import software.amazon.smithy.swift.codegen.swiftmodules.SwiftTypes

/*
Generates a swift middleware struct like the following:

public struct {name}Middleware {

    public let id: String = {name}

    {members}

    {init}
}
{extensions}
 */
class MiddlewareGenerator(
    private val writer: SwiftWriter,
    private val middleware: Middleware
) {
    fun generate() {
        writer.openBlock("public struct \$L {", "}", middleware.typeName) {
            writer.write("public let id: \$N = \$S", SwiftTypes.String, middleware.id)
            writer.write("")
            middleware.properties.forEach {
                val memberName = it.key
                val memberType = it.value
                writer.write("let $memberName: \$N", memberType)
                writer.write("")
            }
            middleware.generateInit()
        }

        middleware.renderExtensions()
    }
}

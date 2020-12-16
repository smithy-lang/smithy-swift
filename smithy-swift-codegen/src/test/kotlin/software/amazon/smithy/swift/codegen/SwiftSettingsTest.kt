/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test
import software.amazon.smithy.model.node.Node
import software.amazon.smithy.model.shapes.ShapeId

class SwiftSettingsTest : TestsBase() {
    @Test fun `infers default service`() {
        val model = createModelFromSmithy(smithyTestResourceName = "simple-service.smithy")

        val settings = SwiftSettings.from(model, Node.objectNodeBuilder()
            .withMember("module", Node.from("example"))
            .withMember("moduleVersion", Node.from("1.0.0"))
            .withMember("homepage", Node.from("https://docs.amplify.aws/"))
            .withMember("author", Node.from("Amazon Web Services"))
            .withMember("gitRepo", Node.from("https://github.com/aws-amplify/amplify-codegen.git"))
            .withMember("swiftVersion", Node.from("5.1.0"))
            .build())

        assertEquals(ShapeId.from("smithy.example#Example"), settings.service)
        assertEquals("example", settings.moduleName)
        assertEquals("1.0.0", settings.moduleVersion)
        assertEquals("https://docs.amplify.aws/", settings.homepage)
        assertEquals("Amazon Web Services", settings.author)
        assertEquals("https://github.com/aws-amplify/amplify-codegen.git", settings.gitRepo)
    }
}

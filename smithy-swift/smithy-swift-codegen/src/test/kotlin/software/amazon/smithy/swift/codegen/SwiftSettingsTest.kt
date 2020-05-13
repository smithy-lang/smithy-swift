/*
 * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

package software.amazon.smithy.swift.codegen

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test
import software.amazon.smithy.model.node.Node
import software.amazon.smithy.model.shapes.ShapeId

class SwiftSettingsTest : TestsBase() {
    @Test fun `infers default service`() {
        val model = createModelFromSmithy(smithyTestResourceName = "simple-service.smithy")

        val settings = SwiftSettings.from(model!!, Node.objectNodeBuilder()
            .withMember("module", Node.from("example"))
            .withMember("moduleVersion", Node.from("1.0.0"))
            .withMember("homepage", Node.from("https://docs.amplify.aws/"))
            .withMember("author", Node.from("Amazon Web Services"))
            .withMember("gitRepo", Node.from("https://github.com/aws-amplify/amplify-codegen.git"))
            .build())

        assertEquals(ShapeId.from("smithy.example#Example"), settings.service)
        assertEquals("example", settings.moduleName)
        assertEquals("1.0.0", settings.moduleVersion)
        assertEquals("https://docs.amplify.aws/", settings.homepage)
        assertEquals("Amazon Web Services", settings.author)
        assertEquals("https://github.com/aws-amplify/amplify-codegen.git", settings.gitRepo)
    }
}

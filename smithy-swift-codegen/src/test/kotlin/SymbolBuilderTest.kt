/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.kotlin.codegen.model
// copied and modified from https://github.com/awslabs/smithy-kotlin/blob/b386392b1cd7cc73a9bc08bedcff0c109487b74f/smithy-kotlin-codegen/src/test/kotlin/software/amazon/smithy/kotlin/codegen/model/SymbolBuilderTest.kt
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Assertions.assertFalse
import org.junit.jupiter.api.Test
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.model.buildSymbol

class SymbolBuilderTest {

    @Test
    fun `it builds symbols`() {
        val x = buildSymbol {
            name = "Foo"
            dependencies += SwiftDependency.CLIENT_RUNTIME
            reference {
                name = "MyRef"
            }
            namespace = "com.mypkg"
            definitionFile = "Foo.swift"
            declarationFile = "Foo.swift"
            defaultValue = "fooey"
            properties {
                set("key", "value")
                set("key2", "value2")
                remove("key2")
            }
        }

        assertEquals("Foo", x.name)
        assertEquals("com.mypkg", x.namespace)
        assertEquals("Foo.swift", x.declarationFile)
        assertEquals("Foo.swift", x.definitionFile)
        assertEquals("value", x.getProperty("key").get())
        assertFalse(x.getProperty("key2").isPresent)
        assertEquals(1, x.references.size)
        assertEquals(1, x.dependencies.size)
    }
}

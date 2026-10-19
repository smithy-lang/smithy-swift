package software.amazon.smithy.swift.codegen.codegencomponents

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.swift.codegen.SwiftCodegenPlugin
import software.amazon.smithy.swift.codegen.SwiftWriter
import software.amazon.smithy.swift.codegen.asSmithyModel
import software.amazon.smithy.swift.codegen.defaultSettings
import software.amazon.smithy.swift.codegen.model.defaultValue
import software.amazon.smithy.swift.codegen.model.defaultValueFromClosure
import software.amazon.smithy.swift.codegen.utils.clientName

class SwiftSymbolProviderTest {
    // See https://smithy.io/2.0/aws/aws-core.html#using-sdk-service-id-for-client-naming
    @Test
    fun `it produces the correct string transformation for client names`() {
        assertEquals("APIGateway", "API Gateway".clientName())
        assertEquals("Lambda", "Lambda".clientName())
        assertEquals("ElastiCache", "ElastiCache".clientName())
        assertEquals("ApiGatewayManagementApi", "ApiGatewayManagementApi".clientName())
        assertEquals("MigrationHubConfig", "MigrationHub Config".clientName())
        assertEquals("IoTFleetHub", "IoTFleetHub".clientName())
        assertEquals("IoT1ClickProjects", "IoT 1Click Projects".clientName())
        assertEquals("DynamoDB", "DynamoDB".clientName())
        assertEquals("ExampleClient", "Example Client".clientName())
        assertEquals("ExampleClient", " Example Client ".clientName())
        assertEquals("EMRServerless", "EMR Serverless".clientName())
    }

    private val bigNumberModel =
        """
        ${'$'}version: "2.0"

        namespace com.test

        use aws.protocols#restJson1

        @restJson1
        service Example {
            version: "1.0"
            operations: []
        }

        bigInteger CustomBigInteger

        structure Numbers {
            bigInteger: BigInteger
            bigDecimal: BigDecimal
            custom: CustomBigInteger
            @default(0)
            zeroInteger: BigInteger
            @default(1.50)
            decimalWithDefault: BigDecimal
            @default(123456789012345678901234567890)
            largeInteger: BigInteger
        }
        """.trimIndent().asSmithyModel()

    private fun symbolFor(
        member: String,
        forceSchemaBased: Boolean,
    ) = SwiftCodegenPlugin
        .createSymbolProvider(bigNumberModel, bigNumberModel.defaultSettings(forceSchemaBased = forceSchemaBased))
        .toSymbol(bigNumberModel.expectShape(ShapeId.from("com.test#Numbers\$$member")))

    @Test
    fun `it maps bigInteger and bigDecimal to Int and Double when not schema-based`() {
        assertEquals("Swift.Int", symbolFor("bigInteger", false).fullName)
        assertEquals("Swift.Double", symbolFor("bigDecimal", false).fullName)
        assertEquals("Swift.Int", symbolFor("custom", false).fullName)
    }

    @Test
    fun `it maps bigInteger and bigDecimal to CRT types when schema-based`() {
        assertEquals("AwsCommonRuntimeKit.BigInteger", symbolFor("bigInteger", true).fullName)
        assertEquals("AwsCommonRuntimeKit.BigDecimal", symbolFor("bigDecimal", true).fullName)
        assertEquals("AwsCommonRuntimeKit.BigInteger", symbolFor("custom", true).fullName)
    }

    @Test
    fun `it renders bigInteger and bigDecimal defaults as literals when not schema-based`() {
        assertEquals("0", symbolFor("zeroInteger", false).defaultValue())
        assertEquals("1.5", symbolFor("decimalWithDefault", false).defaultValue())
    }

    @Test
    fun `it renders bigInteger and bigDecimal defaults as constructor calls when schema-based`() {
        val writer = SwiftWriter("test", moduleName = "TestModule")
        assertEquals(
            "try! AwsCommonRuntimeKit.BigInteger(\"0\")",
            symbolFor("zeroInteger", true).defaultValueFromClosure(writer),
        )
        assertEquals(
            "try! AwsCommonRuntimeKit.BigDecimal(\"1.5\")",
            symbolFor("decimalWithDefault", true).defaultValueFromClosure(writer),
        )
        assertEquals(
            "try! AwsCommonRuntimeKit.BigInteger(\"123456789012345678901234567890\")",
            symbolFor("largeInteger", true).defaultValueFromClosure(writer),
        )
    }
}

package software.amazon.smithy.swift.codegen.codegencomponents

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test
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
}

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.utils

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

class SymbolVisitorTest {

    // See https://awslabs.github.io/smithy/1.0/spec/aws/aws-core.html#using-sdk-service-id-for-client-naming
    @Test
    fun `it produces the correct string transformation for client names`() {
        assertEquals("ApiGateway", "API Gateway".clientName())
        assertEquals("Lambda", "Lambda".clientName())
        assertEquals("ElastiCache", "ElastiCache".clientName())
        assertEquals("ApiGatewayManagementApi", "ApiGatewayManagementApi".clientName())
        assertEquals("MigrationHubConfig", "MigrationHub Config".clientName())
        assertEquals("IoTFleetHub", "IoTFleetHub".clientName())
        assertEquals("Iot1ClickProjects", "IoT 1Click Projects".clientName())
        assertEquals("DynamoDb", "DynamoDB".clientName())
        assertEquals("ExampleClient", "Example Client".clientName())
        assertEquals("ExampleClient", " Example Client ".clientName())
    }
}

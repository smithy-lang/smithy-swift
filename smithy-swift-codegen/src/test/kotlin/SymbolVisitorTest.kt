package software.amazon.smithy.swift.codegen

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

class SymbolVisitorTest {

    // See https://awslabs.github.io/smithy/1.0/spec/aws/aws-core.html#using-sdk-service-id-for-client-naming
    @Test
    fun `it produces the correct string transformation for client names`() {
        assertEquals("ApiGateway", "API Gateway".clientName())
        assertEquals("Lambda", "Lambda".clientName())
        assertEquals("Elasticache", "ElastiCache".clientName())
        assertEquals("Apigatewaymanagementapi", "ApiGatewayManagementApi".clientName())
        assertEquals("MigrationhubConfig", "MigrationHub Config".clientName())
        assertEquals("Iotfleethub", "IoTFleetHub".clientName())
        assertEquals("Iot1clickProjects", "IoT 1Click Projects".clientName())
        assertEquals("ExampleClient", "Example Client".clientName())
        assertEquals("ExampleClient", " Example Client ".clientName())
        assertEquals("ExampleClient", "Example Client ".clientName())
        assertEquals("ExampleClient", "Exámple Client ".clientName())
        
    }
}
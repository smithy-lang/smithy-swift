package software.amazon.smithy.swift.codegen.codegencomponents

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import software.amazon.smithy.aws.traits.protocols.AwsJson1_0Trait
import software.amazon.smithy.aws.traits.protocols.AwsJson1_1Trait
import software.amazon.smithy.aws.traits.protocols.AwsQueryTrait
import software.amazon.smithy.aws.traits.protocols.Ec2QueryTrait
import software.amazon.smithy.aws.traits.protocols.RestJson1Trait
import software.amazon.smithy.aws.traits.protocols.RestXmlTrait
import software.amazon.smithy.model.Model
import software.amazon.smithy.model.knowledge.ServiceIndex
import software.amazon.smithy.model.shapes.ServiceShape
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.shapes.StringShape
import software.amazon.smithy.model.traits.ProtocolDefinitionTrait
import software.amazon.smithy.protocol.traits.Rpcv2CborTrait
import software.amazon.smithy.swift.codegen.SwiftSettings
import software.amazon.smithy.swift.codegen.UnresolvableProtocolException
import software.amazon.smithy.swift.codegen.asSmithy
import software.amazon.smithy.swift.codegen.defaultSettings

class SwiftSettingsTest {
    @Test fun `infers default service`() {
        val model = javaClass.classLoader.getResource("simple-service.smithy").asSmithy()

        val settings = model.defaultSettings(serviceShapeId = "smithy.example#Example")

        assertEquals(ShapeId.from("smithy.example#Example"), settings.service)
        assertEquals("example", settings.moduleName)
        assertEquals("1.0.0", settings.moduleVersion)
        assertEquals("https://docs.amplify.aws/", settings.homepage)
        assertEquals("Amazon Web Services", settings.author)
        assertEquals("https://github.com/aws-amplify/amplify-codegen.git", settings.gitRepo)
        assertEquals(false, settings.mergeModels)
        assertEquals(false, settings.internalClient)
    }

    // Smithy Protocol Selection Tests

    // Row 1: SDK supports all protocols
    private val allProtocolsSupported =
        setOf(
            Rpcv2CborTrait.ID,
            AwsJson1_0Trait.ID,
            AwsJson1_1Trait.ID,
            RestJson1Trait.ID,
            RestXmlTrait.ID,
            AwsQueryTrait.ID,
            Ec2QueryTrait.ID,
        )

    @Test
    fun `when SDK supports all protocols and service has rpcv2Cbor and awsJson1_0 then resolves rpcv2Cbor`() {
        val settings = createTestSettings()
        val service = createServiceWithProtocols(setOf(Rpcv2CborTrait.ID, AwsJson1_0Trait.ID))
        val serviceIndex = createServiceIndex(service)

        val resolvedProtocol = settings.resolveServiceProtocol(serviceIndex, service, allProtocolsSupported)

        assertEquals(Rpcv2CborTrait.ID, resolvedProtocol)
    }

    @Test
    fun `when SDK supports all protocols and service has only rpcv2Cbor then resolves rpcv2Cbor`() {
        val settings = createTestSettings()
        val service = createServiceWithProtocols(setOf(Rpcv2CborTrait.ID))
        val serviceIndex = createServiceIndex(service)

        val resolvedProtocol = settings.resolveServiceProtocol(serviceIndex, service, allProtocolsSupported)

        assertEquals(Rpcv2CborTrait.ID, resolvedProtocol)
    }

    @Test
    fun `when SDK supports all protocols and service has rpcv2Cbor awsJson1_0 and awsQuery then resolves rpcv2Cbor`() {
        val settings = createTestSettings()
        val service = createServiceWithProtocols(setOf(Rpcv2CborTrait.ID, AwsJson1_0Trait.ID, AwsQueryTrait.ID))
        val serviceIndex = createServiceIndex(service)

        val resolvedProtocol = settings.resolveServiceProtocol(serviceIndex, service, allProtocolsSupported)

        assertEquals(Rpcv2CborTrait.ID, resolvedProtocol)
    }

    @Test
    fun `when SDK supports all protocols and service has awsJson1_0 and awsQuery then resolves awsJson1_0`() {
        val settings = createTestSettings()
        val service = createServiceWithProtocols(setOf(AwsJson1_0Trait.ID, AwsQueryTrait.ID))
        val serviceIndex = createServiceIndex(service)

        val resolvedProtocol = settings.resolveServiceProtocol(serviceIndex, service, allProtocolsSupported)

        assertEquals(AwsJson1_0Trait.ID, resolvedProtocol)
    }

    @Test
    fun `when SDK supports all protocols and service has only awsQuery then resolves awsQuery`() {
        val settings = createTestSettings()
        val service = createServiceWithProtocols(setOf(AwsQueryTrait.ID))
        val serviceIndex = createServiceIndex(service)

        val resolvedProtocol = settings.resolveServiceProtocol(serviceIndex, service, allProtocolsSupported)

        assertEquals(AwsQueryTrait.ID, resolvedProtocol)
    }

    // Row 2: SDK does not support rpcv2Cbor
    private val withoutRpcv2CborSupport =
        setOf(
            AwsJson1_0Trait.ID,
            AwsJson1_1Trait.ID,
            RestJson1Trait.ID,
            RestXmlTrait.ID,
            AwsQueryTrait.ID,
            Ec2QueryTrait.ID,
        )

    @Test
    fun `when SDK does not support rpcv2Cbor and service has rpcv2Cbor and awsJson1_0 then resolves awsJson1_0`() {
        val settings = createTestSettings()
        val service = createServiceWithProtocols(setOf(Rpcv2CborTrait.ID, AwsJson1_0Trait.ID))
        val serviceIndex = createServiceIndex(service)

        val resolvedProtocol = settings.resolveServiceProtocol(serviceIndex, service, withoutRpcv2CborSupport)

        assertEquals(AwsJson1_0Trait.ID, resolvedProtocol)
    }

    @Test
    fun `when SDK does not support rpcv2Cbor and service has only rpcv2Cbor then throws exception`() {
        val settings = createTestSettings()
        val service = createServiceWithProtocols(setOf(Rpcv2CborTrait.ID))
        val serviceIndex = createServiceIndex(service)

        assertThrows<UnresolvableProtocolException> {
            settings.resolveServiceProtocol(serviceIndex, service, withoutRpcv2CborSupport)
        }
    }

    @Test
    fun `when SDK does not support rpcv2Cbor and service has rpcv2Cbor awsJson1_0 and awsQuery then resolves awsJson1_0`() {
        val settings = createTestSettings()
        val service = createServiceWithProtocols(setOf(Rpcv2CborTrait.ID, AwsJson1_0Trait.ID, AwsQueryTrait.ID))
        val serviceIndex = createServiceIndex(service)

        val resolvedProtocol = settings.resolveServiceProtocol(serviceIndex, service, withoutRpcv2CborSupport)

        assertEquals(AwsJson1_0Trait.ID, resolvedProtocol)
    }

    @Test
    fun `when SDK does not support rpcv2Cbor and service has awsJson1_0 and awsQuery then resolves awsJson1_0`() {
        val settings = createTestSettings()
        val service = createServiceWithProtocols(setOf(AwsJson1_0Trait.ID, AwsQueryTrait.ID))
        val serviceIndex = createServiceIndex(service)

        val resolvedProtocol = settings.resolveServiceProtocol(serviceIndex, service, withoutRpcv2CborSupport)

        assertEquals(AwsJson1_0Trait.ID, resolvedProtocol)
    }

    @Test
    fun `when SDK does not support rpcv2Cbor and service has only awsQuery then resolves awsQuery`() {
        val settings = createTestSettings()
        val service = createServiceWithProtocols(setOf(AwsQueryTrait.ID))
        val serviceIndex = createServiceIndex(service)

        val resolvedProtocol = settings.resolveServiceProtocol(serviceIndex, service, withoutRpcv2CborSupport)

        assertEquals(AwsQueryTrait.ID, resolvedProtocol)
    }

    // Helper functions

    private fun createTestSettings(): SwiftSettings =
        SwiftSettings(
            service = ShapeId.from("test#TestService"),
            moduleName = "TestModule",
            moduleVersion = "1.0.0",
            moduleDescription = "Test module",
            author = "Test Author",
            homepage = "https://test.com",
            sdkId = "Test",
            gitRepo = "https://github.com/test/test.git",
            swiftVersion = "5.7",
            mergeModels = false,
            copyrightNotice = "// Test copyright",
            visibility = "public",
            internalClient = false,
            modelPath = "/path/to/model.json",
        )

    private fun createServiceWithProtocols(protocols: Set<ShapeId>): ServiceShape {
        var builder =
            ServiceShape
                .builder()
                .id("test#TestService")
                .version("1.0")

        // Apply the actual protocol traits to the service
        for (protocolId in protocols) {
            when (protocolId) {
                Rpcv2CborTrait.ID -> builder = builder.addTrait(Rpcv2CborTrait.builder().build())
                AwsJson1_0Trait.ID -> builder = builder.addTrait(AwsJson1_0Trait.builder().build())
                AwsJson1_1Trait.ID -> builder = builder.addTrait(AwsJson1_1Trait.builder().build())
                RestJson1Trait.ID -> builder = builder.addTrait(RestJson1Trait.builder().build())
                RestXmlTrait.ID -> builder = builder.addTrait(RestXmlTrait.builder().build())
                AwsQueryTrait.ID -> builder = builder.addTrait(AwsQueryTrait())
                Ec2QueryTrait.ID -> builder = builder.addTrait(Ec2QueryTrait())
            }
        }

        return builder.build()
    }

    private fun createServiceIndex(service: ServiceShape): ServiceIndex {
        val modelBuilder = Model.builder()

        // Add the service shape
        modelBuilder.addShape(service)

        // Add protocol definition shapes to the model
        // These are needed for ServiceIndex to recognize the protocols
        val protocolShapes =
            listOf(
                Rpcv2CborTrait.ID,
                AwsJson1_0Trait.ID,
                AwsJson1_1Trait.ID,
                RestJson1Trait.ID,
                RestXmlTrait.ID,
                AwsQueryTrait.ID,
                Ec2QueryTrait.ID,
            )

        for (protocolId in protocolShapes) {
            // Create a shape that represents the protocol definition
            // and add the ProtocolDefinitionTrait to it
            val protocolShape =
                StringShape
                    .builder()
                    .id(protocolId)
                    .addTrait(
                        ProtocolDefinitionTrait
                            .builder()
                            .build(),
                    ).build()
            modelBuilder.addShape(protocolShape)
        }

        val model = modelBuilder.build()
        return ServiceIndex.of(model)
    }
}

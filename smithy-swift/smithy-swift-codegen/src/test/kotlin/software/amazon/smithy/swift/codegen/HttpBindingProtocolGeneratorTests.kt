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

import io.kotest.matchers.comparables.shouldBeEqualComparingTo
import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Assertions.assertTrue
import org.junit.jupiter.api.Test
import software.amazon.smithy.aws.traits.protocols.RestJson1Trait
import software.amazon.smithy.build.MockManifest
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.model.traits.TimestampFormatTrait
import software.amazon.smithy.swift.codegen.integration.HttpBindingProtocolGenerator
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class MockHttpProtocolGenerator : HttpBindingProtocolGenerator() {
    override val defaultContentType: String = "application/json"
    override val defaultTimestampFormat: TimestampFormatTrait.Format = TimestampFormatTrait.Format.DATE_TIME
    override val protocol: ShapeId = RestJson1Trait.ID

    override fun generateProtocolUnitTests(ctx: ProtocolGenerator.GenerationContext) {}
}

// NOTE: protocol conformance is mostly handled by the protocol tests suite
class HttpBindingProtocolGeneratorTests : TestsBase() {
    var model = createModelFromSmithy("http-binding-protocol-generator-test.smithy")

    data class TestContext(val ctx: ProtocolGenerator.GenerationContext, val manifest: MockManifest, val generator: MockHttpProtocolGenerator)

    private fun newTestContext(): TestContext {
        val manifest = MockManifest()
        val provider: SymbolProvider = SwiftCodegenPlugin.createSymbolProvider(model, "Example")
        val serviceShapeIdWithNamespace = "com.test#Example"
        val service = model.getShape(ShapeId.from(serviceShapeIdWithNamespace)).get().asServiceShape().get()
        val settings = SwiftSettings.from(model, buildDefaultSwiftSettingsObjectNode(serviceShapeIdWithNamespace))
        model = AddOperationShapes.execute(model, settings.getService(model), settings.moduleName)
        val delegator = SwiftDelegator(settings, model, manifest, provider)
        val generator = MockHttpProtocolGenerator()
        val ctx = ProtocolGenerator.GenerationContext(settings, model, service, provider, listOf(), generator.protocol, delegator)
        return TestContext(ctx, manifest, generator)
    }

    val newTestContext = newTestContext()

    init {
        newTestContext.generator.generateSerializers(newTestContext.ctx)
        newTestContext.generator.generateProtocolClient(newTestContext.ctx)
        newTestContext.ctx.delegator.flushWriters()
    }

    @Test
    fun `it creates smoke test request builder`() {
        val contents = getModelFileContents("example", "SmokeTestRequest+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
                """
                    extension SmokeTestRequest: HttpRequestBinding {
                        public func buildHttpRequest(method: HttpMethodType, path: String) -> HttpRequest {
                            var queryItems: [URLQueryItem] = [URLQueryItem]()
                            if let query1 = query1 {
                                let queryItem = URLQueryItem(name: "Query1", value: String(query1))
                                queryItems.append(queryItem)
                            }
                            let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
                            var headers = HttpHeaders()
                            headers.add(name: "Content-Type", value: "application/json")
                            if let header1 = header1 {
                                headers.add(name: "X-Header1", value: String(header1))
                            }
                            if let header2 = header2 {
                                headers.add(name: "X-Header2", value: String(header2))
                            }
                            return HttpRequest(method: method, endpoint: endpoint, headers: headers)
                        }
                    }
                """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds request for explicit string payloads`() {
        val contents = getModelFileContents("example", "ExplicitStringRequest+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
                extension ExplicitStringRequest: HttpRequestBinding {
                    public func buildHttpRequest(method: HttpMethodType, path: String) -> HttpRequest {
                        var queryItems: [URLQueryItem] = [URLQueryItem]()
                        let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
                        var headers = HttpHeaders()
                        headers.add(name: "Content-Type", value: "text/plain")
                        return HttpRequest(method: method, endpoint: endpoint, headers: headers)
                    }
                }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds request for explicit blob payloads`() {
        val contents = getModelFileContents("example", "ExplicitBlobRequest+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
                extension ExplicitBlobRequest: HttpRequestBinding {
                    public func buildHttpRequest(method: HttpMethodType, path: String) -> HttpRequest {
                        var queryItems: [URLQueryItem] = [URLQueryItem]()
                        let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
                        var headers = HttpHeaders()
                        headers.add(name: "Content-Type", value: "application/octet-stream")
                        return HttpRequest(method: method, endpoint: endpoint, headers: headers)
                    }
                }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds request for explicit streaming blob payloads`() {
        val contents = getModelFileContents("example", "ExplicitBlobStreamRequest+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
                extension ExplicitBlobStreamRequest: HttpRequestBinding {
                    public func buildHttpRequest(method: HttpMethodType, path: String) -> HttpRequest {
                        var queryItems: [URLQueryItem] = [URLQueryItem]()
                        let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
                        var headers = HttpHeaders()
                        headers.add(name: "Content-Type", value: "application/octet-stream")
                        return HttpRequest(method: method, endpoint: endpoint, headers: headers)
                    }
                }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds request for explicit struct payloads`() {
        val contents = getModelFileContents("example", "ExplicitStructRequest+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
                extension ExplicitStructRequest: HttpRequestBinding {
                    public func buildHttpRequest(method: HttpMethodType, path: String) -> HttpRequest {
                        var queryItems: [URLQueryItem] = [URLQueryItem]()
                        let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
                        var headers = HttpHeaders()
                        headers.add(name: "Content-Type", value: "application/json")
                        return HttpRequest(method: method, endpoint: endpoint, headers: headers)
                    }
                }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds request for operation inputs with lists`() {
        val contents = getModelFileContents("example", "ListInputRequest+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
                extension ListInputRequest: HttpRequestBinding {
                    public func buildHttpRequest(method: HttpMethodType, path: String) -> HttpRequest {
                        var queryItems: [URLQueryItem] = [URLQueryItem]()
                        let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
                        var headers = HttpHeaders()
                        headers.add(name: "Content-Type", value: "application/json")
                        return HttpRequest(method: method, endpoint: endpoint, headers: headers)
                    }
                }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it builds request with enums as raw values in the header`() {
        val contents = getModelFileContents("example", "EnumInputRequest+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
                extension EnumInputRequest: HttpRequestBinding {
                    public func buildHttpRequest(method: HttpMethodType, path: String) -> HttpRequest {
                        var queryItems: [URLQueryItem] = [URLQueryItem]()
                        let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
                        var headers = HttpHeaders()
                        headers.add(name: "Content-Type", value: "application/json")
                        if let enumHeader = enumHeader {
                            headers.add(name: "X-EnumHeader", value: String(enumHeader.rawValue))
                        }
                        return HttpRequest(method: method, endpoint: endpoint, headers: headers)
                    }
                }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates http builder for timestamps with format`() {
        val contents = getModelFileContents("example", "TimestampInputRequest+HttpRequestBinding.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension TimestampInputRequest: HttpRequestBinding {
                public func buildHttpRequest(method: HttpMethodType, path: String) -> HttpRequest {
                    var queryItems: [URLQueryItem] = [URLQueryItem]()
                    if let queryTimestamp = queryTimestamp {
                        let queryItem = URLQueryItem(name: "qtime", value: String(queryTimestamp.iso8601FractionalSecondsString()))
                        queryItems.append(queryItem)
                    }
                    if let queryTimestampList = queryTimestampList {
                        queryTimestampList.forEach { queryItemValue in
                            let queryItem = URLQueryItem(name: "qtimeList", value: String(queryItemValue.iso8601FractionalSecondsString()))
                            queryItems.append(queryItem)
                        }
                    }
                    let endpoint = Endpoint(host: "my-api.us-east-2.amazonaws.com", path: path, queryItems: queryItems)
                    var headers = HttpHeaders()
                    headers.add(name: "Content-Type", value: "application/json")
                    if let headerEpoch = headerEpoch {
                        headers.add(name: "X-Epoch", value: String(headerEpoch.rfc5322String()))
                    }
                    if let headerHttpDate = headerHttpDate {
                        headers.add(name: "X-Date", value: String(headerHttpDate.rfc5322String()))
                    }
                    return HttpRequest(method: method, endpoint: endpoint, headers: headers)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates encodable conformance in correct file`() {
        assertTrue(newTestContext.manifest.hasFile("/example/models/SmokeTestRequest+Encodable.swift"))
    }

    @Test
    fun `it creates encodable conformance for nested structures`() {
        // test that a struct member of an input operation shape also gets encodable conformance
        assertTrue(newTestContext.manifest.hasFile("/example/models/Nested+Encodable.swift"))
        // these are non-top level shapes reachable from an operation input and thus require encodable conformance
        assertTrue(newTestContext.manifest.hasFile("/example/models/Nested2+Encodable.swift"))
        assertTrue(newTestContext.manifest.hasFile("/example/models/Nested3+Encodable.swift"))
        assertTrue(newTestContext.manifest.hasFile("/example/models/Nested4+Encodable.swift"))
    }

    @Test
    fun `it creates smoke test request encodable conformance`() {
        val contents = getModelFileContents("example", "SmokeTestRequest+Encodable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension SmokeTestRequest: Encodable {
                private enum CodingKeys: String, CodingKey {
                    case payload1
                    case payload2
                    case payload3
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(payload1, forKey: .payload1)
                    try container.encode(payload2, forKey: .payload2)
                    try container.encode(payload3, forKey: .payload3)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it encodes nested documents with aggregate shapes`() {
        val contents = getModelFileContents("example", "Nested4+Encodable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension Nested4: Encodable {
                private enum CodingKeys: String, CodingKey {
                    case intList
                    case intMap
                    case member1
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let intList = intList {
                        var intListContainer = container.nestedUnkeyedContainer(forKey: .intList)
                        for intlist0 in intList {
                            try intListContainer.encode(intlist0)
                        }
                    }
                    if let intMap = intMap {
                        var intMapContainer = container.nestedContainer(keyedBy: Key.self, forKey: .intMap)
                        for (key0, intmap0) in intMap {
                            try intMapContainer.encode(intmap0, forKey: Key(stringValue: key0))
                        }
                    }
                    try container.encode(member1, forKey: .member1)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it provides encodable conformance to operation inputs with timestamps`() {
        val contents = getModelFileContents("example", "TimestampInputRequest+Encodable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension TimestampInputRequest: Encodable {
                private enum CodingKeys: String, CodingKey {
                    case dateTime
                    case epochSeconds
                    case httpDate
                    case normal
                    case timestampList
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(dateTime?.iso8601FractionalSecondsString(), forKey: .dateTime)
                    try container.encode(epochSeconds?.timeIntervalSince1970, forKey: .epochSeconds)
                    try container.encode(httpDate?.rfc5322String(), forKey: .httpDate)
                    try container.encode(normal?.iso8601FractionalSecondsString(), forKey: .normal)
                    if let timestampList = timestampList {
                        var timestampListContainer = container.nestedUnkeyedContainer(forKey: .timestampList)
                        for timestamplist0 in timestampList {
                            var timestamplist0Container = timestampListContainer.nestedUnkeyedContainer()
                            for timestamp1 in timestamplist0 {
                                try timestamplist0Container.encode(timestamp1.iso8601FractionalSecondsString())
                            }
                        }
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it encodes maps correctly`() {
        val contents = getModelFileContents("example", "MapInputRequest+Encodable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension MapInputRequest: Encodable {
                private enum CodingKeys: String, CodingKey {
                    case blobMap
                    case dateMap
                    case enumMap
                    case intMap
                    case structMap
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    if let blobMap = blobMap {
                        var blobMapContainer = container.nestedContainer(keyedBy: Key.self, forKey: .blobMap)
                        for (key0, blobmap0) in blobMap {
                            try blobMapContainer.encode(blobmap0, forKey: Key(stringValue: key0))
                        }
                    }
                    if let dateMap = dateMap {
                        var dateMapContainer = container.nestedContainer(keyedBy: Key.self, forKey: .dateMap)
                        for (key0, datemap0) in dateMap {
                            try dateMapContainer.encode(datemap0.iso8601FractionalSecondsString(), forKey: Key(stringValue: key0))
                        }
                    }
                    if let enumMap = enumMap {
                        var enumMapContainer = container.nestedContainer(keyedBy: Key.self, forKey: .enumMap)
                        for (key0, enummap0) in enumMap {
                            try enumMapContainer.encode(enummap0.rawValue, forKey: Key(stringValue: key0))
                        }
                    }
                    if let intMap = intMap {
                        var intMapContainer = container.nestedContainer(keyedBy: Key.self, forKey: .intMap)
                        for (key0, intmap0) in intMap {
                            try intMapContainer.encode(intmap0, forKey: Key(stringValue: key0))
                        }
                    }
                    if let structMap = structMap {
                        var structMapContainer = container.nestedContainer(keyedBy: Key.self, forKey: .structMap)
                        for (key0, structmap0) in structMap {
                            try structMapContainer.encode(structmap0, forKey: Key(stringValue: key0))
                        }
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it encodes nested enums correctly`() {
        val contents = getModelFileContents("example", "EnumInputRequest+Encodable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension EnumInputRequest: Encodable {
                private enum CodingKeys: String, CodingKey {
                    case nestedWithEnum
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(nestedWithEnum, forKey: .nestedWithEnum)
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)

        val contents2 = getModelFileContents("example", "NestedEnum+Encodable.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents2 =
            """
            extension NestedEnum: Encodable {
                private enum CodingKeys: String, CodingKey {
                    case myEnum
                }
            
                public func encode(to encoder: Encoder) throws {
                    var container = encoder.container(keyedBy: CodingKeys.self)
                    try container.encode(myEnum.rawValue, forKey: .myEnum)
                }
            }
            """.trimIndent()
        contents2.shouldContainOnlyOnce(expectedContents2)
    }

    @Test
    fun `getSanitizedName generates Swifty name`() {
        val testProtocolName = "aws.rest-json-1.1"
        val sanitizedProtocolName = ProtocolGenerator.getSanitizedName(testProtocolName)
        sanitizedProtocolName.shouldBeEqualComparingTo("AWSRestJson1_1")
    }
}

/*
 *
 *  * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *  *
 *  * Licensed under the Apache License, Version 2.0 (the "License").
 *  * You may not use this file except in compliance with the License.
 *  * A copy of the License is located at
 *  *
 *  *  http://aws.amazon.com/apache2.0
 *  *
 *  * or in the "license" file accompanying this file. This file is distributed
 *  * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 *  * express or implied. See the License for the specific language governing
 *  * permissions and limitations under the License.
 *
 */

package software.amazon.smithy.swift.codegen

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test
import software.amazon.smithy.build.MockManifest
import software.amazon.smithy.codegen.core.SymbolProvider
import software.amazon.smithy.model.shapes.ShapeId
import software.amazon.smithy.swift.codegen.integration.ProtocolGenerator

class HttpProtocolUnitTestRequestGeneratorTests : TestsBase() {
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
        newTestContext.generator.generateProtocolUnitTests(newTestContext.ctx)
        newTestContext.ctx.delegator.flushWriters()
    }

    @Test
    fun `it creates smoke test request test`() {
        val contents = getTestFileContents("example", "SmokeTestRequestTest.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()

        val expectedContents =
            """
    func testSmokeTest() {
        let expected = buildExpectedHttpRequest(
            method: .post,
            path: "/smoketest/{label1}/foo",
            headers: [
                "X-Header1": "Foo",
                "X-Header2": "Bar"
            ],
            queryParams: [
                "Query1=Query 1"
            ],
            body: ""${'"'}
            {
            "payload1": "String",
            "payload2": 2,
            "payload3": {
                "member1": "test string",
                "member2": "test string 2"
                }
            }
            ""${'"'},
            host: host
        )

        let input = SmokeTestRequest(
            header1: "Foo",
            header2: "Bar",
            label1: "label",
            payload1: "String",
            payload2: 2,
            payload3: Nested(
                member1: "test string",
                member2: "test string 2"
),
            query1: "Query 1"
)
        do {
            let actual = try input.buildHttpRequest(method: .post, path: "/smoketest/{label1}/foo", encoder: JSONEncoder())
            let requiredHeaders = ["Content-Length"]
            // assert required headers do exist
            for requiredHeader in requiredHeaders {
                XCTAssertTrue(
                    headerExists(requiredHeader, in: actual.headers.headers),
                    "Required Header:\(requiredHeader) does not exist in headers"
                )
            }
            assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                assertEqualHttpBodyData(expectedHttpBody!, actualHttpBody!)
            })
        } catch let err {
            XCTFail("Failed to encode the input. Error description: \(err)")
        }
    }
                """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates explicit string test`() {
        val contents = getTestFileContents("example", "ExplicitStringRequestTest.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
    func testExplicitString() {
        let expected = buildExpectedHttpRequest(
            method: .post,
            path: "/explicit/string",
            headers: [String: String](),
            queryParams: [String](),
            body: ""${'"'}
            {
            "payload1": "explicit string"
            }
            ""${'"'},
            host: host
        )

        let input = ExplicitStringRequest(
            payload1: "explicit string"
)
        do {
            let actual = try input.buildHttpRequest(method: .post, path: "/explicit/string", encoder: JSONEncoder())
            let requiredHeaders = ["Content-Length"]
            // assert required headers do exist
            for requiredHeader in requiredHeaders {
                XCTAssertTrue(
                    headerExists(requiredHeader, in: actual.headers.headers),
                    "Required Header:\(requiredHeader) does not exist in headers"
                )
            }
            assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                assertEqualHttpBodyData(expectedHttpBody!, actualHttpBody!)
            })
        } catch let err {
            XCTFail("Failed to encode the input. Error description: \(err)")
        }
    }
                """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a unit test for a request without a body`() {
        val contents = getTestFileContents("example", "EmptyInputAndEmptyOutputRequestTest.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
    func testRestJsonEmptyInputAndEmptyOutput() {
        let expected = buildExpectedHttpRequest(
            method: .post,
            path: "/EmptyInputAndEmptyOutput",
            headers: [String: String](),
            queryParams: [String](),
            body: nil,
            host: host
        )

        let input = EmptyInputAndEmptyOutputInput(
)
        do {
            let actual = try input.buildHttpRequest(method: .post, path: "/EmptyInputAndEmptyOutput", encoder: JSONEncoder())
            assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssertNil(actualHttpBody, "The actual HttpBody is not nil as expected")
                XCTAssertNil(expectedHttpBody, "The expected HttpBody is not nil as expected")
            })
        } catch let err {
            XCTFail("Failed to encode the input. Error description: \(err)")
        }
    }
                """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a unit test for a request without a body given an empty object`() {
        val contents = getTestFileContents("example", "SimpleScalarPropertiesRequestTest.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
    func testRestJsonDoesntSerializeNullStructureValues() {
        let expected = buildExpectedHttpRequest(
            method: .put,
            path: "/SimpleScalarProperties",
            headers: [
                "Content-Type": "application/json"
            ],
            queryParams: [String](),
            body: nil,
            host: host
        )

        let input = SimpleScalarPropertiesInputOutput(
            stringValue: nil
)
        do {
            let actual = try input.buildHttpRequest(method: .put, path: "/SimpleScalarProperties", encoder: JSONEncoder())
            assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssertNil(actualHttpBody, "The actual HttpBody is not nil as expected")
                XCTAssertNil(expectedHttpBody, "The expected HttpBody is not nil as expected")
            })
        } catch let err {
            XCTFail("Failed to encode the input. Error description: \(err)")
        }
    }
                """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates a unit test with a string to be converted to data`() {
        val contents = getTestFileContents("example", "StreamingTraitsRequestTest.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
    func testRestJsonStreamingTraitsWithBlob() {
        let expected = buildExpectedHttpRequest(
            method: .post,
            path: "/StreamingTraits",
            headers: [
                "Content-Type": "application/octet-stream",
                "X-Foo": "Foo"
            ],
            queryParams: [String](),
            body: ""${'"'}
            blobby blob blob
            ""${'"'},
            host: host
        )

        let input = StreamingTraitsInputOutput(
            blob: "blobby blob blob".data(using: .utf8),
            foo: "Foo"
)
        do {
            let actual = try input.buildHttpRequest(method: .post, path: "/StreamingTraits", encoder: JSONEncoder())
            assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssertNotNil(actualHttpBody, "The actual HttpBody is nil")
                XCTAssertNotNil(expectedHttpBody, "The expected HttpBody is nil")
                assertEqualHttpBodyData(expectedHttpBody!, actualHttpBody!)
            })
        } catch let err {
            XCTFail("Failed to encode the input. Error description: \(err)")
        }
    }
                """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates unit test with an empty map`() {
        val contents = getTestFileContents("example", "HttpPrefixHeadersRequestTest.swift", newTestContext.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
    func testRestJsonHttpPrefixHeadersAreNotPresent() {
        let expected = buildExpectedHttpRequest(
            method: .get,
            path: "/HttpPrefixHeaders",
            headers: [
                "X-Foo": "Foo"
            ],
            queryParams: [String](),
            body: nil,
            host: host
        )

        let input = HttpPrefixHeadersInputOutput(
            foo: "Foo",
            fooMap: [:            
            ]

)
        do {
            let actual = try input.buildHttpRequest(method: .get, path: "/HttpPrefixHeaders", encoder: JSONEncoder())
            assertEqual(expected, actual, { (expectedHttpBody, actualHttpBody) -> Void in
                XCTAssertNil(actualHttpBody, "The actual HttpBody is not nil as expected")
                XCTAssertNil(expectedHttpBody, "The expected HttpBody is not nil as expected")
            })
        } catch let err {
            XCTFail("Failed to encode the input. Error description: \(err)")
        }
    }
                """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }
}

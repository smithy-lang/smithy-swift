package software.amazon.smithy.swift.codegen

/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class HttpProtocolUnitTestErrorGeneratorTests : HttpProtocolUnitTestResponseGeneratorTests() {
    @Test
    fun `it creates error test for simple error with no payload`() {
        val contents = getTestFileContents("Tests/example", "GreetingWithErrorsErrorTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    func testRestJsonComplexErrorWithNoMessage() async throws {
        guard let httpResponse = buildHttpResponse(
            code: 403,
            headers: [
                "Content-Type": "application/json",
                "X-Amzn-Errortype": "ComplexError",
                "X-Header": "Header"
            ],
            content: .data(Data(""${'"'}
            {
                "TopLevel": "Top level",
                "Nested": {
                    "Fooooo": "bar"
                }
            }
            ""${'"'}.utf8))
        ) else {
            XCTFail("Something is wrong with the created http response")
            return
        }

        let config = try await ExampleClient.Config(
            awsCredentialIdentityResolver: try SmithyTestUtil.dummyIdentityResolver(),
            region: "us-west-2",
            signingRegion: "us-west-2",
            endpointResolver: StaticEndpointResolver(endpoint: try SmithyHTTPAPI.Endpoint(
                urlString: "https://example.com"
            )),
            httpClientEngine: ProtocolResponseTestClient(httpResponse: httpResponse)
        )

        let client = ExampleClient(config: config)

        let input = GreetingWithErrorsInput()

        var operationError: Swift.Error?
        do {
            _ = try await client.greetingWithErrors(input: input)
            XCTFail("Request should have failed")
        } catch {
            operationError = error
        }

        if let actual = operationError as? ComplexError {

            let expected = ComplexError(
                header: "Header",
                nested: ComplexNestedErrorData(
                    foo: "bar"
                ),
                topLevel: "Top level"
            )
            XCTAssertEqual(actual.httpResponse.statusCode, SmithyHTTPAPI.HTTPStatusCode(rawValue: 403))
            XCTAssertEqual(actual, expected)
        } else {
            XCTFail("The deserialized error type does not match expected type")
        }
    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates error test for complex error with payload`() {
        val contents = getTestFileContents("Tests/example", "GreetingWithErrorsErrorTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    func testRestJsonComplexErrorWithNoMessage() async throws {
        guard let httpResponse = buildHttpResponse(
            code: 403,
            headers: [
                "Content-Type": "application/json",
                "X-Amzn-Errortype": "ComplexError",
                "X-Header": "Header"
            ],
            content: .data(Data(""${'"'}
            {
                "TopLevel": "Top level",
                "Nested": {
                    "Fooooo": "bar"
                }
            }
            ""${'"'}.utf8))
        ) else {
            XCTFail("Something is wrong with the created http response")
            return
        }

        let config = try await ExampleClient.Config(
            awsCredentialIdentityResolver: try SmithyTestUtil.dummyIdentityResolver(),
            region: "us-west-2",
            signingRegion: "us-west-2",
            endpointResolver: StaticEndpointResolver(endpoint: try SmithyHTTPAPI.Endpoint(
                urlString: "https://example.com"
            )),
            httpClientEngine: ProtocolResponseTestClient(httpResponse: httpResponse)
        )

        let client = ExampleClient(config: config)

        let input = GreetingWithErrorsInput()

        var operationError: Swift.Error?
        do {
            _ = try await client.greetingWithErrors(input: input)
            XCTFail("Request should have failed")
        } catch {
            operationError = error
        }

        if let actual = operationError as? ComplexError {

            let expected = ComplexError(
                header: "Header",
                nested: ComplexNestedErrorData(
                    foo: "bar"
                ),
                topLevel: "Top level"
            )
            XCTAssertEqual(actual.httpResponse.statusCode, SmithyHTTPAPI.HTTPStatusCode(rawValue: 403))
            XCTAssertEqual(actual, expected)
        } else {
            XCTFail("The deserialized error type does not match expected type")
        }
    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
}

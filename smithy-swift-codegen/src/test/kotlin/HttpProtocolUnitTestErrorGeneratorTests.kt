/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Test

class HttpProtocolUnitTestErrorGeneratorTests : HttpProtocolUnitTestResponseGeneratorTests() {

    @Test
    fun `it creates error test for simple error with no payload`() {
        val contents = getTestFileContents("example", "GreetingWithErrorsErrorTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()

        val expectedContents =
"""
class GreetingWithErrorsComplexErrorTest: HttpResponseTestBase {
    /// Serializes a complex error with no message member
    func testRestJsonComplexErrorWithNoMessage() async throws {
        do {
            guard let httpResponse = buildHttpResponse(
                code: 403,
                headers: [
                    "Content-Type": "application/json",
                    "X-Amzn-Errortype": "ComplexError",
                    "X-Header": "Header"
                ],
                content: .data( ""${'"'}
                {
                    "TopLevel": "Top level",
                    "Nested": {
                        "Fooooo": "bar"
                    }
                }
                ""${'"'}.data(using: .utf8)!)
            ) else {
                XCTFail("Something is wrong with the created http response")
                return
            }

            let decoder = ClientRuntime.JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
            let greetingWithErrorsOutputError = try await GreetingWithErrorsOutputError.makeError(httpResponse: httpResponse, decoder: decoder)

            if let actual = greetingWithErrorsOutputError as? ComplexError {

                let expected = ComplexError(
                    header: "Header",
                    nested: ComplexNestedErrorData(
                        foo: "bar"
                    ),
                    topLevel: "Top level"
                )
                let actualCode = await actual.httpResponse.statusCode
                XCTAssertEqual(actualCode, HttpStatusCode(rawValue: 403))
                XCTAssertEqual(expected.properties.header, actual.properties.header)
                XCTAssertEqual(expected.properties.topLevel, actual.properties.topLevel)
                XCTAssertEqual(expected.properties.nested, actual.properties.nested)
            } else {
                XCTFail("The deserialized error type does not match expected type")
            }

        } catch let err {
            XCTFail(err.localizedDescription)
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates error test for complex error with payload`() {
        val contents = getTestFileContents("example", "GreetingWithErrorsErrorTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()

        val expectedContents =
"""
class GreetingWithErrorsComplexErrorTest: HttpResponseTestBase {
    /// Serializes a complex error with no message member
    func testRestJsonComplexErrorWithNoMessage() async throws {
        do {
            guard let httpResponse = buildHttpResponse(
                code: 403,
                headers: [
                    "Content-Type": "application/json",
                    "X-Amzn-Errortype": "ComplexError",
                    "X-Header": "Header"
                ],
                content: .data( ""${'"'}
                {
                    "TopLevel": "Top level",
                    "Nested": {
                        "Fooooo": "bar"
                    }
                }
                ""${'"'}.data(using: .utf8)!)
            ) else {
                XCTFail("Something is wrong with the created http response")
                return
            }

            let decoder = ClientRuntime.JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            decoder.nonConformingFloatDecodingStrategy = .convertFromString(positiveInfinity: "Infinity", negativeInfinity: "-Infinity", nan: "NaN")
            let greetingWithErrorsOutputError = try await GreetingWithErrorsOutputError.makeError(httpResponse: httpResponse, decoder: decoder)

            if let actual = greetingWithErrorsOutputError as? ComplexError {

                let expected = ComplexError(
                    header: "Header",
                    nested: ComplexNestedErrorData(
                        foo: "bar"
                    ),
                    topLevel: "Top level"
                )
                let actualCode = await actual.httpResponse.statusCode
                XCTAssertEqual(actualCode, HttpStatusCode(rawValue: 403))
                XCTAssertEqual(expected.properties.header, actual.properties.header)
                XCTAssertEqual(expected.properties.topLevel, actual.properties.topLevel)
                XCTAssertEqual(expected.properties.nested, actual.properties.nested)
            } else {
                XCTFail("The deserialized error type does not match expected type")
            }

        } catch let err {
            XCTFail(err.localizedDescription)
        }
    }
}
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
}

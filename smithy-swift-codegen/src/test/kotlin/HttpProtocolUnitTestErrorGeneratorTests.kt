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
        val expectedContents = """
    func testRestJsonComplexErrorWithNoMessage() async throws {
        do {
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

            let greetingWithErrorsOutputError = try await wireResponseErrorClosure(GreetingWithErrorsOutputError.httpErrorBinding, wireResponseDocumentBinding())(httpResponse)

            if let actual = greetingWithErrorsOutputError as? ComplexError {

                let expected = ComplexError(
                    header: "Header",
                    nested: ComplexNestedErrorData(
                        foo: "bar"
                    ),
                    topLevel: "Top level"
                )
                XCTAssertEqual(actual.httpResponse.statusCode, HttpStatusCode(rawValue: 403))
                XCTAssertEqual(expected.properties.header, actual.properties.header)
                XCTAssertEqual(expected.properties.topLevel, actual.properties.topLevel)
                XCTAssertEqual(expected.properties.nested, actual.properties.nested)
            } else {
                XCTFail("The deserialized error type does not match expected type")
            }

        } catch {
            XCTFail(error.localizedDescription)
        }
    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `it creates error test for complex error with payload`() {
        val contents = getTestFileContents("example", "GreetingWithErrorsErrorTest.swift", ctx.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents = """
    func testRestJsonComplexErrorWithNoMessage() async throws {
        do {
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

            let greetingWithErrorsOutputError = try await wireResponseErrorClosure(GreetingWithErrorsOutputError.httpErrorBinding, wireResponseDocumentBinding())(httpResponse)

            if let actual = greetingWithErrorsOutputError as? ComplexError {

                let expected = ComplexError(
                    header: "Header",
                    nested: ComplexNestedErrorData(
                        foo: "bar"
                    ),
                    topLevel: "Top level"
                )
                XCTAssertEqual(actual.httpResponse.statusCode, HttpStatusCode(rawValue: 403))
                XCTAssertEqual(expected.properties.header, actual.properties.header)
                XCTAssertEqual(expected.properties.topLevel, actual.properties.topLevel)
                XCTAssertEqual(expected.properties.nested, actual.properties.nested)
            } else {
                XCTFail("The deserialized error type does not match expected type")
            }

        } catch {
            XCTFail(error.localizedDescription)
        }
    }
"""
        contents.shouldContainOnlyOnce(expectedContents)
    }
}

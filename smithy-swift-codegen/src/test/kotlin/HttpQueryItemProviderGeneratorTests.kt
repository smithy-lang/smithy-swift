/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import io.kotest.matchers.string.shouldContainOnlyOnce
import org.junit.jupiter.api.Assertions
import org.junit.jupiter.api.Test
import java.util.Optional

class HttpQueryItemProviderGeneratorTests {
    @Test
    fun `001 it creates query item provider with idempotency token trait for httpQuery`() {
        val context = setupTests("http-binding-protocol-generator-test.smithy", "com.test#Example")
        val contents =
            getModelFileContents("example", "QueryIdempotencyTokenAutoFillInput+QueryItemProvider.swift", context.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension QueryIdempotencyTokenAutoFillInput: ClientRuntime.QueryItemProvider {
                public var queryItems: [ClientRuntime.URLQueryItem] {
                    get throws {
                        var items = [ClientRuntime.URLQueryItem]()
                        if let token = token {
                            let tokenQueryItem = ClientRuntime.URLQueryItem(name: "token".urlPercentEncoding(), value: Swift.String(token).urlPercentEncoding())
                            items.append(tokenQueryItem)
                        }
                        return items
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `002 it creates query item middleware for timestamps with format`() {
        val context = setupTests("http-binding-protocol-generator-test.smithy", "com.test#Example")
        val contents = getModelFileContents("example", "TimestampInputInput+QueryItemProvider.swift", context.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension TimestampInputInput: ClientRuntime.QueryItemProvider {
                public var queryItems: [ClientRuntime.URLQueryItem] {
                    get throws {
                        var items = [ClientRuntime.URLQueryItem]()
                        if let queryTimestamp = queryTimestamp {
                            let queryTimestampQueryItem = ClientRuntime.URLQueryItem(name: "qtime".urlPercentEncoding(), value: Swift.String(TimestampFormatter(format: .dateTime).string(from: queryTimestamp)).urlPercentEncoding())
                            items.append(queryTimestampQueryItem)
                        }
                        if let queryTimestampList = queryTimestampList {
                            queryTimestampList.forEach { queryItemValue in
                                let queryItem = ClientRuntime.URLQueryItem(name: "qtimeList".urlPercentEncoding(), value: Swift.String(TimestampFormatter(format: .dateTime).string(from: queryItemValue)).urlPercentEncoding())
                                items.append(queryItem)
                            }
                        }
                        return items
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `003 it creates query item middleware smoke test`() {
        val context = setupTests("http-binding-protocol-generator-test.smithy", "com.test#Example")
        val contents = getModelFileContents("example", "SmokeTestInput+QueryItemProvider.swift", context.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension SmokeTestInput: ClientRuntime.QueryItemProvider {
                public var queryItems: [ClientRuntime.URLQueryItem] {
                    get throws {
                        var items = [ClientRuntime.URLQueryItem]()
                        if let query1 = query1 {
                            let query1QueryItem = ClientRuntime.URLQueryItem(name: "Query1".urlPercentEncoding(), value: Swift.String(query1).urlPercentEncoding())
                            items.append(query1QueryItem)
                        }
                        return items
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `004 httpQueryParams only should not have BodyMiddleware extension`() {
        val context = setupTests("http-query-params-stringmap.smithy", "com.test#Example")
        Assertions.assertEquals(
            Optional.empty<String>(),
            context.manifest.getFileString("/example/models/AllQueryStringTypesInput+BodyMiddleware.swift")
        )
    }

    @Test
    fun `005 httpQueryParams on StringMap`() {
        val context = setupTests("http-query-params-stringmap.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "/example/models/AllQueryStringTypesInput+QueryItemProvider.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension AllQueryStringTypesInput: ClientRuntime.QueryItemProvider {
                public var queryItems: [ClientRuntime.URLQueryItem] {
                    get throws {
                        var items = [ClientRuntime.URLQueryItem]()
                        if let queryStringList = queryStringList {
                            queryStringList.forEach { queryItemValue in
                                let queryItem = ClientRuntime.URLQueryItem(name: "StringList".urlPercentEncoding(), value: Swift.String(queryItemValue).urlPercentEncoding())
                                items.append(queryItem)
                            }
                        }
                        if let queryString = queryString {
                            let queryStringQueryItem = ClientRuntime.URLQueryItem(name: "String".urlPercentEncoding(), value: Swift.String(queryString).urlPercentEncoding())
                            items.append(queryStringQueryItem)
                        }
                        if let queryParamsMapOfStrings = queryParamsMapOfStrings {
                            let currentQueryItemNames = items.map({${'$'}0.name})
                            queryParamsMapOfStrings.forEach { key0, value0 in
                                if !currentQueryItemNames.contains(key0) {
                                    let queryItem = ClientRuntime.URLQueryItem(name: key0.urlPercentEncoding(), value: value0.urlPercentEncoding())
                                    items.append(queryItem)
                                }
                            }
                        }
                        return items
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `006 httpQueryParams on stringListMap`() {
        val context = setupTests("http-query-params-stringlistmap.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "/example/models/QueryParamsAsStringListMapInput+QueryItemProvider.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension QueryParamsAsStringListMapInput: ClientRuntime.QueryItemProvider {
                public var queryItems: [ClientRuntime.URLQueryItem] {
                    get throws {
                        var items = [ClientRuntime.URLQueryItem]()
                        if let qux = qux {
                            let quxQueryItem = ClientRuntime.URLQueryItem(name: "corge".urlPercentEncoding(), value: Swift.String(qux).urlPercentEncoding())
                            items.append(quxQueryItem)
                        }
                        if let foo = foo {
                            let currentQueryItemNames = items.map({${'$'}0.name})
                            foo.forEach { key0, value0 in
                                if !currentQueryItemNames.contains(key0) {
                                    value0.forEach { value1 in
                                        let queryItem = ClientRuntime.URLQueryItem(name: key0.urlPercentEncoding(), value: value1.urlPercentEncoding())
                                        items.append(queryItem)
                                    }
                                }
                            }
                        }
                        return items
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `007 query precedence with httpQuery and httpQueryParams`() {
        val context = setupTests("http-query-params-precedence.smithy", "com.test#Example")
        val contents = getFileContents(context.manifest, "/example/models/QueryPrecedenceInput+QueryItemProvider.swift")
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension QueryPrecedenceInput: ClientRuntime.QueryItemProvider {
                public var queryItems: [ClientRuntime.URLQueryItem] {
                    get throws {
                        var items = [ClientRuntime.URLQueryItem]()
                        if let foo = foo {
                            let fooQueryItem = ClientRuntime.URLQueryItem(name: "bar".urlPercentEncoding(), value: Swift.String(foo).urlPercentEncoding())
                            items.append(fooQueryItem)
                        }
                        if let baz = baz {
                            let currentQueryItemNames = items.map({${'$'}0.name})
                            baz.forEach { key0, value0 in
                                if !currentQueryItemNames.contains(key0) {
                                    let queryItem = ClientRuntime.URLQueryItem(name: key0.urlPercentEncoding(), value: value0.urlPercentEncoding())
                                    items.append(queryItem)
                                }
                            }
                        }
                        return items
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    @Test
    fun `008 it handles required http query items`() {
        val context = setupTests("http-binding-protocol-generator-test.smithy", "com.test#Example")
        val contents = getModelFileContents("example", "RequiredHttpFieldsInput+QueryItemProvider.swift", context.manifest)
        contents.shouldSyntacticSanityCheck()
        val expectedContents =
            """
            extension RequiredHttpFieldsInput: ClientRuntime.QueryItemProvider {
                public var queryItems: [ClientRuntime.URLQueryItem] {
                    get throws {
                        var items = [ClientRuntime.URLQueryItem]()
                        guard let query1 = query1 else {
                            let message = "Creating a URL Query Item failed. query1 is required and must not be nil."
                            throw ClientRuntime.ClientError.unknownError(message)
                        }
                        let query1QueryItem = ClientRuntime.URLQueryItem(name: "Query1".urlPercentEncoding(), value: Swift.String(query1).urlPercentEncoding())
                        items.append(query1QueryItem)
                        guard let query2 = query2 else {
                            let message = "Creating a URL Query Item failed. query2 is required and must not be nil."
                            throw ClientRuntime.ClientError.unknownError(message)
                        }
                        query2.forEach { queryItemValue in
                            let queryItem = ClientRuntime.URLQueryItem(name: "Query2".urlPercentEncoding(), value: Swift.String(TimestampFormatter(format: .dateTime).string(from: queryItemValue)).urlPercentEncoding())
                            items.append(queryItem)
                        }
                        guard let query3 = query3 else {
                            let message = "Creating a URL Query Item failed. query3 is required and must not be nil."
                            throw ClientRuntime.ClientError.unknownError(message)
                        }
                        let query3QueryItem = ClientRuntime.URLQueryItem(name: "Query3".urlPercentEncoding(), value: Swift.String(query3).urlPercentEncoding())
                        items.append(query3QueryItem)
                        return items
                    }
                }
            }
            """.trimIndent()
        contents.shouldContainOnlyOnce(expectedContents)
    }

    private fun setupTests(smithyFile: String, serviceShapeId: String): TestContext {
        val context = TestContext.initContextFrom(smithyFile, serviceShapeId)
        context.generator.generateSerializers(context.generationCtx)
        context.generator.generateProtocolClient(context.generationCtx)
        context.generator.generateDeserializers(context.generationCtx)
        context.generator.generateCodableConformanceForNestedTypes(context.generationCtx)
        context.generationCtx.delegator.flushWriters()
        return context
    }
}

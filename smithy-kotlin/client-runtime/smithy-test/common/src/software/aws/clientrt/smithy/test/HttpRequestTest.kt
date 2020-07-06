/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
package software.aws.clientrt.smithy.test

import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNotNull
import kotlin.test.assertTrue
import software.aws.clientrt.http.HttpMethod
import software.aws.clientrt.http.engine.HttpClientEngine
import software.aws.clientrt.http.request.HttpRequestBuilder
import software.aws.clientrt.http.response.HttpResponse
import software.aws.clientrt.http.util.urlEncodeComponent
import software.aws.clientrt.testing.runSuspendTest

// marker exception thrown by roundTripping
private class MockEngineException : RuntimeException()

/**
 * Setup a [Smithy HTTP Request Test](https://awslabs.github.io/smithy/1.0/spec/http-protocol-compliance-tests.html#httprequesttests).
 *
 * # Example
 * ```
 * fun fooTest() = httpRequestTest {
 *
 *     // setup the expected request that was built
 *     expected {
 *         uri = "/foo/bar"
 *     }
 *
 *     // run the service operation with the provided (mock) [HttpClientEngine]
 *     operation { mockEngine ->
 *         val input = MyInput {
 *             param = "param1"
 *         }
 *
 *         val service = blah()
 *         service.doOperation(input)
 *     }
 * }
 * ```
 */
fun httpRequestTest(block: HttpRequestTestBuilder.() -> Unit) = runSuspendTest {
    // setup expectations
    val testBuilder = HttpRequestTestBuilder().apply(block)

    // provide the mock engine
    lateinit var actual: HttpRequestBuilder
    val mockEngine = object : HttpClientEngine {
        override suspend fun roundTrip(requestBuilder: HttpRequestBuilder): HttpResponse {
            // capture the request that was build by the service operation
            actual = requestBuilder
            // FIXME - I don't love this...it requires the service call to be the last
            // statement in the operation{} block...
            throw MockEngineException()
        }
    }

    // run the actual service operation provided by the caller
    try {
        testBuilder.runOperation(mockEngine)
    } catch (ex: Exception) {
        // we expect a MockEngineException, anything else propagate back
        if (ex !is MockEngineException) throw ex
    }

    assertRequest(testBuilder.expected.build(), actual)
}

private fun assertRequest(expected: ExpectedHttpRequest, actual: HttpRequestBuilder) {
    // run the assertions
    assertEquals(expected.method, actual.method)
    assertEquals(expected.uri, actual.url.path)

    // have to deal with URL encoding
    expected.queryParams.forEach { (name, value) ->
        val actualValues = actual.url.parameters.getAll(name)
        assertNotNull(actualValues, "expected query parameter `$name`; no values found")
        assertTrue(actualValues.map { it.urlEncodeComponent() }.contains(value), "expected query name value pair: `$name:$value` not found")
    }

    expected.forbiddenQueryParams.forEach {
        assertFalse(actual.url.parameters.contains(it), "forbidden query parameter `$it` found")
    }

    expected.requiredQueryParams.forEach {
        assertTrue(actual.url.parameters.contains(it), "expected required query parameter `$it`")
    }

    expected.headers.forEach { (name, value) ->
        assertTrue(actual.headers.contains(name, value), "expected header `$name` with value `$value`")
    }

    expected.forbiddenHeaders.forEach {
        assertFalse(actual.headers.contains(it), "forbidden header `$it` found")
    }
    expected.requiredHeaders.forEach {
        assertTrue(actual.headers.contains(it), "expected required header `$it`")
    }

    // expected.expectedBody?.let {
    //     TODO()
    // }

    // expected.expectedBodyMediaType?.let {
    //     TODO()
    // }
}

data class ExpectedHttpRequest(
    // the HTTP method expected
    val method: HttpMethod = HttpMethod.GET,
    // expected path without the query string (e.g. /foo/bar)
    val uri: String = "",
    // query parameter names AND the associated varues that must appear
    val queryParams: List<Pair<String, String>> = listOf(),
    // query parameter names that MUST not appear
    val forbiddenQueryParams: List<String> = listOf(),
    // query parameter names that MUST appear but no assertion on varues
    val requiredQueryParams: List<String> = listOf(),
    // header names AND values that must appear
    val headers: Map<String, String> = mapOf(),
    // header names that must not appear
    val forbiddenHeaders: List<String> = listOf(),
    // header names that must appear but no assertion on varues
    val requiredHeaders: List<String> = listOf(),
    // if no body is defined no assertions are made about it
    val body: String? = null,
    // if not defined no assertion is made
    val bodyMediaType: String? = null
)

class ExpectedHttpRequestBuilder {
    var method: HttpMethod = HttpMethod.GET
    var uri: String = ""
    var queryParams: List<Pair<String, String>> = listOf()
    var forbiddenQueryParams: List<String> = listOf()
    var requiredQueryParams: List<String> = listOf()
    var headers: Map<String, String> = mapOf()
    var forbiddenHeaders: List<String> = listOf()
    var requiredHeaders: List<String> = listOf()
    var body: String? = null
    var bodyMediaType: String? = null

    fun build(): ExpectedHttpRequest =
        ExpectedHttpRequest(
            this.method,
            this.uri,
            this.queryParams,
            this.forbiddenQueryParams,
            this.requiredQueryParams,
            this.headers,
            this.forbiddenHeaders,
            this.requiredHeaders,
            this.body,
            this.bodyMediaType
        )
}

class HttpRequestTestBuilder {
    internal var runOperation: suspend (mockEngine: HttpClientEngine) -> Unit = {}
    internal var expected = ExpectedHttpRequestBuilder()

    /**
     * Setup the expected HTTP request that the service operation should produce
     */
    fun expected(block: ExpectedHttpRequestBuilder.() -> Unit) {
        expected.apply(block)
    }

    /**
     * Setup the service operation to run. The [HttpClientEngine] to use for the test is
     * provided as input to the function. The [block] is responsible for setting up the
     * service client with the provided engine, providing the input, and executing the
     * operation (which *MUST* be the last statement in the block).
     */
    fun operation(block: suspend (mockEngine: HttpClientEngine) -> Unit) {
        runOperation = block
    }
}

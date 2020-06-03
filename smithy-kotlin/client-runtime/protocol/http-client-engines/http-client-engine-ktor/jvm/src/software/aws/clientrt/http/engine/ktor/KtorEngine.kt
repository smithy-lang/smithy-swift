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
package software.aws.clientrt.http.engine.ktor

import io.ktor.client.HttpClient
import io.ktor.client.engine.okhttp.OkHttp
import io.ktor.client.request.request
import io.ktor.client.statement.HttpStatement
import kotlin.coroutines.coroutineContext
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.launch
import software.aws.clientrt.http.HttpStatusCode
import software.aws.clientrt.http.engine.HttpClientEngine
import software.aws.clientrt.http.engine.HttpClientEngineConfig
import software.aws.clientrt.http.request.HttpRequestBuilder
import software.aws.clientrt.http.response.HttpResponse as SdkHttpResponse

/**
 * JVM [HttpClientEngine] backed by Ktor
 */
class KtorEngine(val config: HttpClientEngineConfig) : HttpClientEngine {
    val client: HttpClient

    init {
        client = HttpClient(OkHttp) {
            // TODO - propagate applicable client engine config to OkHttp engine
        }
    }

    override suspend fun roundTrip(requestBuilder: HttpRequestBuilder): SdkHttpResponse {
        val callContext = coroutineContext
        val builder = KtorRequestAdapter(requestBuilder, callContext).toBuilder()

        val waiter = Waiter()
        var resp: SdkHttpResponse? = null

        // run the request in another coroutine
        GlobalScope.launch(callContext + Dispatchers.IO) {
            client.request<HttpStatement>(builder).execute { httpResp ->
                // we have a lifetime problem here...the stream (and HttpResponse instance) are only valid
                // until the end of this block. We don't know if the consumer wants to read the content fully or
                // stream it. We need to wait until the entire content has been read before leaving the block and
                // releasing the underlying network resources...

                // when the body has been read fully we will signal again which allows the block to exit
                val body = KtorHttpBody(httpResp.content) { waiter.signal() }

                resp = SdkHttpResponse(
                    HttpStatusCode.fromValue(httpResp.status.value),
                    KtorHeaders(httpResp.headers),
                    body,
                    requestBuilder.build()
                )

                // signal that the resp is now ready and can be forwarded to the sdk client
                waiter.signal()

                // wait for the receiving end to finish with these resources
                waiter.wait()
            }
        }

        // wait for the response to be available, the content will be read as a stream
        waiter.wait()

        return resp!!
    }

    override fun close() {
        client.close()
    }
}

/**
 * Simple notify mechanism that waits for a signal
 */
internal class Waiter {
    private val channel = Channel<Unit>(0)

    // wait for the signal
    suspend fun wait() { channel.receive() }

    // give the signal to continue
    fun signal() { channel.offer(Unit) }
}

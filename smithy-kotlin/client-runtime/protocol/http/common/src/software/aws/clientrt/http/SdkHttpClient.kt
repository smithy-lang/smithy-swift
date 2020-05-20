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
package software.aws.clientrt.http

import software.aws.clientrt.http.engine.HttpClientEngine

/**
 * An HTTP client capable of round tripping requests and responses
 *
 * **NOTE**: This is not a general purpose HTTP client. It is meant for generated SDK use.
 */
class SdkHttpClient(
    val engine: HttpClientEngine,
    val config: HttpClientConfig
) {

    init {
        // wire up the features
        config.install(this)
    }

    /**
     * Request pipeline (middleware stack). Responsible for transforming inputs into an outgoing [HttpRequest]
     */
    val requestPipeline = HttpRequestPipeline()

    /**
     * Response pipeline. Responsible for transforming [HttpResponse] to the expected type
     */
    val responsePipeline = HttpResponsePipeline()

    /**
     * Shutdown this HTTP client and close any resources. The client will no longer be capable of making requests.
     */
    fun close() {
        engine.close()
    }
}

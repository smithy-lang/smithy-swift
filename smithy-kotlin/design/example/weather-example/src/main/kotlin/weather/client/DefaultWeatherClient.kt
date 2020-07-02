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
package weather.client

import software.aws.clientrt.http.*
import software.aws.clientrt.http.engine.HttpClientEngineConfig
import software.aws.clientrt.http.engine.ktor.KtorEngine
import software.aws.clientrt.http.feature.DefaultRequest
import software.aws.clientrt.http.feature.DefaultValidateResponse
import software.aws.clientrt.http.feature.HttpSerde
import software.aws.clientrt.http.request.HttpRequestBuilder
import software.aws.clientrt.http.request.url
import software.aws.clientrt.serde.json.JsonSerdeProvider
import weather.model.structure.*


class DefaultWeatherClient: WeatherClient {
    private val client: SdkHttpClient

    init {
        val config = HttpClientEngineConfig()
        client = sdkHttpClient(KtorEngine(config)) {
            install(HttpSerde) {
                serdeProvider = JsonSerdeProvider()
            }

            // request defaults
            install(DefaultRequest) {
                url.scheme = Protocol.HTTP
                url.host = "127.0.0.1"
                url.port = 8000
            }

            // this is what will be installed by the generic smithy-kotlin codegenerator
            install(DefaultValidateResponse)
        }
    }

    override suspend fun getCurrentTime(): GetCurrentTimeOutput {
        val path = "/current-time"
        val httpMethod = HttpMethod.GET

        val requestBuilder = HttpRequestBuilder().apply {
            url { this.path = path }
            method = httpMethod
        }

        return client.roundTrip(requestBuilder, GetCurrentTimeOutputDeserializer())
    }

    override suspend fun getCity(input: GetCityInput): GetCityOutput {
        val path = "/cities/{cityId}"
        val httpMethod = HttpMethod.GET

        requireNotNull(input.cityId) { "Must provide a value for cityId." }

        val requestBuilder = HttpRequestBuilder().apply {
            url { this.path = path.replace("{cityId}", input.cityId) }
            method = httpMethod
        }

        return client.roundTrip(requestBuilder, GetCityOutputDeserializer())
    }

    override suspend fun getCityImage(input: GetCityImageInput): GetCityImageOutput {
        requireNotNull(input.cityId) { "Must provide a value for cityId." }

        val path = "/cities/{cityId}/image"
        val httpMethod: HttpMethod = HttpMethod.GET

        val requestBuilder = HttpRequestBuilder().apply {
            url { this.path = path.replace("{cityId}", input.cityId) }
            method = httpMethod
        }

        return client.roundTrip(requestBuilder, GetCityImageOutputDeserializer())
    }
}
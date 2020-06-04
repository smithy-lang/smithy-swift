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
package com.amazonaws.service.s3.transform

import com.amazonaws.service.runtime.Deserializer
import com.amazonaws.service.runtime.HttpDeserialize
import com.amazonaws.service.s3.model.PutObjectResponse
import software.aws.clientrt.http.HttpBody
import software.aws.clientrt.http.response.HttpResponse


class PutObjectResponseDeserializer : HttpDeserialize {
    override suspend fun deserialize(response: HttpResponse, deserializer: Deserializer): Any {
        println(response.headers.entries())
        println(response.body.contentLength)
        val body = response.body
        
        when(body) {
            is HttpBody.Streaming -> {
                val source = body.readFrom()
                println(source.isClosedForRead)
                // FIXME - without reading the content (even empty body) the ktor (sdk) engine won't exit it's waiting state
                // source.cancel(null)
            }
        }
        
        
        return PutObjectResponse {
            eTag = response.headers["ETag"]
            expiration = response.headers["X-Amz-Expiration"]
            requestCharged = response.headers["X-Amz-Request-Charged"]
            sseCustomerAlgorithm = response.headers["x-amz-server-side-encryption-customer-algorithm"]
            sseCustomerKeyMd5 = response.headers["x-amz-server-side-encryption-customer-key-MD5"]
            sseKmsEncryptionContext = response.headers["x-amz-server-side-encryption-context"]
            sseKmsKeyId = response.headers["x-amz-server-side-encryption-aws"]
            serverSideEncryption = response.headers["x-amz-server-side-encryption"]
            versionId = response.headers["x-amz-version-id"]
        }
    }
}
/*
 * Copyright 2020 Amazon.com, Inc. or its affiliates. All Rights Reserved.
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
package software.amazon.smithy.swift.codegen

import software.amazon.smithy.aws.traits.protocols.RestJson1Trait
import software.amazon.smithy.codegen.core.CodegenException
import software.amazon.smithy.model.shapes.ServiceShape
import java.util.*

/**
 *
 */
enum class SerializationProtocol {
    RESTJSON1 {
        override fun getEncoderInstanceAsString() = "JSONEncoder()"
        override fun getDecoderInstanceAsString() = "JSONDecoder()"
    },

    XML {
        override fun getEncoderInstanceAsString() = "XMLEncoder()"
        override fun getDecoderInstanceAsString() = "XMLDecoder()"
    };

    abstract fun getEncoderInstanceAsString(): String

    abstract fun getDecoderInstanceAsString(): String

    companion object {
        fun resolve(serviceShape: ServiceShape): SerializationProtocol {
            var serializationProtocol: SerializationProtocol? = null
            if (serviceShape.getTrait(RestJson1Trait::class.java).isPresent)
                serializationProtocol = RESTJSON1
            else if (serviceShape.getTrait(RestJson1Trait::class.java).isPresent)
                serializationProtocol = XML

            // TODO:: add more serialization protocols
            return serializationProtocol ?: throw UnresolvableSerializationProtocolException(
                "Could not resolve the serialization protocol for the service."
            )
        }
    }
}

class UnresolvableSerializationProtocolException(message: String) : CodegenException(message)
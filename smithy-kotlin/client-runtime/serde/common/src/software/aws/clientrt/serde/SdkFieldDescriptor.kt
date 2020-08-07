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
package software.aws.clientrt.serde

import kotlin.reflect.KClass

/**
 * Metadata that may influence how a field is serialized and deserialized.
 *
 */
sealed class SdkFieldDescriptor

/**
 * Describes a JSON field.
 *
 * @property serialName name to use when serializing/deserializing this field (e.g. in JSON, this is the property name)
 */
class JsonFieldDescriptor(val serialName: String) : SdkFieldDescriptor() {
    // only relevant in the context of an object descriptor
    var index: Int = 0
}

/**
 * Describes an XML node / field.
 *
 * @property nodeName name of containing node
 * @property index index of field in structure
 */
data class XmlFieldDescriptor(val nodeName: String, val index: Int = 0): SdkFieldDescriptor()

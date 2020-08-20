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

/**
 * Metadata to describe how a given member property maps to serialization.
 *
 * @property serialName name to use when serializing/deserializing this field (e.g. in JSON, this is the property name)
 */
/*
data class SdkFieldDescriptor(val serialName: String) {
    // only relevant in the context of an object descriptor
    var index: Int = 0
}
*/

interface FieldTrait
class XmlAttribute : FieldTrait
class XmlMap(
    val parent: String? = "map",
    val entry: String = "entry",
    val keyName: String = "key",
    val valueName: String = "value",
    val flattened: Boolean = false
) : FieldTrait
class XmlList(
    val elementName: String = "element"
) : FieldTrait
class ObjectStruct(val fields: List<SdkFieldDescriptor>) : FieldTrait

sealed class SerialKind {
    object Integer : SerialKind()
    object Long : SerialKind()
    object Double : SerialKind()
    object String: SerialKind()
    object Boolean: SerialKind()
    object Short: SerialKind()
    object Float: SerialKind()

    data class Map(val traits: Set<FieldTrait> = emptySet()) : SerialKind()
    data class List(val traits: Set<FieldTrait> = emptySet()): SerialKind()
    data class Struct(val traits: Set<FieldTrait> = emptySet()): SerialKind()
}

open class SdkFieldDescriptor(val serialName: String?, val kind: SerialKind, var index: Int = 0)
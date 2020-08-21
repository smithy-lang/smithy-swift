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

sealed class SerialKind(val traits: Set<FieldTrait> = emptySet()) {
    class Integer : SerialKind()
    class Long : SerialKind()
    class Double : SerialKind()
    class String: SerialKind()
    class Boolean: SerialKind()
    class Short: SerialKind()
    class Float: SerialKind()
    class Map(traits: Set<FieldTrait> = emptySet()) : SerialKind(traits)
    class List(traits: Set<FieldTrait> = emptySet()): SerialKind(traits)
    class Struct(traits: Set<FieldTrait> = emptySet()): SerialKind(traits)

    inline fun <reified TExpected : FieldTrait> expectTrait(): TExpected =
        traits.find { it::class == TExpected::class } as TExpected
}

open class SdkFieldDescriptor(val serialName: String?, val kind: SerialKind, var index: Int = 0)


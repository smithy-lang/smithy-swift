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
 * Metadata container for all fields of an object/class
 */
class SdkObjectDescriptor private constructor(builder: BuilderImpl) : SdkNamedFieldDescriptor(
    builder.serialName!!,
    SerialKind.Struct(
        setOf(ObjectStruct(builder.fields))
    ),
    0
) {
    companion object {
        fun build(block: DslBuilder.() -> Unit): SdkObjectDescriptor = BuilderImpl().apply(block).build()
    }

    fun fields(): List<SdkNamedFieldDescriptor> {
        val objectStruct = (kind as SerialKind.Struct).traits.first { it is ObjectStruct } as ObjectStruct

        return objectStruct.fields
    }

    interface DslBuilder {
        /**
         * Declare a field belonging to this object
         */
        fun field(field: SdkNamedFieldDescriptor)
        fun serialName(name: String)
        fun build(): SdkObjectDescriptor
    }

    private class BuilderImpl : DslBuilder {
        val fields: MutableList<SdkNamedFieldDescriptor> = mutableListOf()
        var serialName: String? = null
        val kind: SerialKind = SerialKind.Struct()

        override fun field(field: SdkNamedFieldDescriptor) {
            field.index = fields.size
            fields.add(field)
        }

        override fun serialName(name: String) {
            this.serialName = name
        }

        override fun build(): SdkObjectDescriptor = SdkObjectDescriptor(this)
    }
}

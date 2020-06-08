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
 * Holds the attributes and properties of an object being serialized. When XML is added, tag attributes
 * might be added here. They do not exist in JSON so we currently only have serialName as a proptery in
 * the descriptor.
 *
 * @property serialName In JSON, this is the key when serializing.
 * @property writeFieldName This is used to determine whether a field name should be written
 * for the given value that is being serialized. in JSON, the main container's name is not
 * written.
 */
class SdkFieldDescriptor(val serialName: String, val writeFieldName: Boolean = true)

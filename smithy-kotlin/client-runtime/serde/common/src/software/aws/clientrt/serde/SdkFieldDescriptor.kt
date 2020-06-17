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
 * SdkFieldDescriptor is metadata that may influence how a field is serialized and deserialized.
 *
 * @property name In JSON, this is the key when serializing.
 * @property writeFieldName This is used to determine whether a field name should be written
 * for the given value that is being serialized. in JSON, the main container's name is not
 * written.
 */
class SdkFieldDescriptor(val name: String)

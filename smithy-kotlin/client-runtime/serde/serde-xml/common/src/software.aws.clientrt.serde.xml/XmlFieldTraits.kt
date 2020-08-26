/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.aws.clientrt.serde.xml

import software.aws.clientrt.serde.FieldTrait

// NOTE: The XML specific Traits which describe names will need to be amended to include namespace (or a Qualified Name)
// If it's determined we need to serialize from/to specific namespaces.
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
class XmlAttribute(val name: String, val namespace: String? = null) : FieldTrait
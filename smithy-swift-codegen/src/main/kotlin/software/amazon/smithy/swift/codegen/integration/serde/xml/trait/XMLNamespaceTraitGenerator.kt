/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

package software.amazon.smithy.swift.codegen.integration.serde.xml.trait

import software.amazon.smithy.model.shapes.Shape
import software.amazon.smithy.model.traits.XmlNamespaceTrait
import software.amazon.smithy.swift.codegen.ClientRuntimeTypes
import software.amazon.smithy.swift.codegen.SmithyXMLTypes
import software.amazon.smithy.swift.codegen.SwiftDependency
import software.amazon.smithy.swift.codegen.SwiftWriter

class XMLNamespaceTraitGenerator(val key: String, val value: String) {
    companion object {
        fun construct(shape: Shape): XMLNamespaceTraitGenerator? {
            if (shape.hasTrait(XmlNamespaceTrait::class.java)) {
                val trait = shape.getTrait(XmlNamespaceTrait::class.java).get()
                val key = if (trait.prefix.isPresent) "xmlns:${trait.prefix.get()}" else "xmlns"
                val namespaceValue = trait.uri
                return XMLNamespaceTraitGenerator(key, namespaceValue)
            }
            return null
        }
    }

    fun render(writer: SwiftWriter, container: String): XMLNamespaceTraitGenerator {
        writer.addImport(SwiftDependency.SMITHY_XML.target)
        writer.write("try $container.encode(\"$value\", forKey: \$N(\$S, location: .attribute))", SmithyXMLTypes.XMLCodingKey, key)
        return this
    }

    fun appendKey(xmlNamespaces: MutableSet<String>): XMLNamespaceTraitGenerator {
        xmlNamespaces.add(key)
        return this
    }
}

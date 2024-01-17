//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import libxml2
import struct Foundation.Data

extension Reader {

    public static func from(data: Data) throws -> Reader {
        var data = data
        let count = data.count

        // Create a buffer to hold the XML data
        let buffer = data.withUnsafeMutableBytes { unsafeMutableRawBufferPtr in
            xmlBufferCreateStatic(unsafeMutableRawBufferPtr.baseAddress, count)
        }
        guard let buffer else { return Reader() }

        // Read the buffer into a XML document tree
        guard let doc = xmlReadMemory(buffer.pointee.content, Int32(count), "", "UTF-8", 0) else { return Reader() }

        // Get rootNode ptr. Just a ptr to inside the doc struct, so no memory allocated
        guard let rootNode = xmlDocGetRootElement(doc) else { return Reader() }

        // Convert the XML root node into a Reader tree
        guard let reader = try Reader.create(from: rootNode) else { throw XMLError.invalidNode }

        // Release memory
        xmlFree(buffer)
        xmlFreeDoc(doc)

        return reader
    }

    private static func create(from xmlNodePtr: xmlNodePtr) throws -> Reader? {

        // Only element nodes and attribute nodes are supported.  nodeInfoLocation is nil for all others.
        guard let location = xmlNodePtr.pointee.type.nodeInfoLocation else { return nil }

        // This is the namespace defined on this node, if any
        let namespaceDef = Self.namespace(xmlNodePtr.pointee.nsDef)

        // This is the namespace that applies to this node
        let namespace = Self.namespace(xmlNodePtr.pointee.ns)

        // Get the name for the node as a Swift string.
        let name = xmlNodePtr.pointee.name.withMemoryRebound(to: CChar.self, capacity: 0) { cStringPtr in
            String(cString: cStringPtr, encoding: .utf8)
        }
        guard let name else { throw XMLError.invalidNodeName }

        // Create a new Reader for this node.
        let parent = Reader(nodeInfo: .init(name, location: location, namespaceDef: namespaceDef, namespace: namespace))

        // Get the content (i.e. element text) for this node.  Convert it to a Swift string.
        let contentPtr = xmlNodeGetContent(xmlNodePtr)
        let content = contentPtr?.withMemoryRebound(to: CChar.self, capacity: 0) { cStringPtr in
            String(cString: cStringPtr, encoding: .utf8)
        }
        parent.content = content
        xmlFree(contentPtr)

        // Get the head of a linked list of this node's children.
        var childXmlNodePtr: xmlNodePtr? = xmlNodePtr.pointee.children

        // Loop through all children.
        while childXmlNodePtr != nil {

            // Create a new Reader from this child if possible, and add it to the parent.
            if let child = try create(from: childXmlNodePtr!) {
                parent.addChild(child)
            }

            // Advance current child to next in list
            childXmlNodePtr = childXmlNodePtr?.pointee.next
        }

        // Get the head of the linked list of this node's attributes.
        var xmlAttrPtr: xmlAttrPtr? = xmlNodePtr.pointee.properties

        // Loop through all attributes.
        while xmlAttrPtr != nil {

            // Get the namespace for this attribute
            let namespace = Self.namespace(xmlAttrPtr?.pointee.ns)

            // Get the attribute name as a C string.
            let attrName = xmlAttrPtr!.pointee.name.withMemoryRebound(to: CChar.self, capacity: 0) { attrNamePtr in
                String(cString: attrNamePtr, encoding: .utf8)
            }

            if let attrName, !attrName.isEmpty {

                // Create a new Reader node for this attribute
                let child = Reader(nodeInfo: .init(attrName, location: .attribute, namespace: namespace))

                // Get the attribute content as a C string
                let contentPtr = xmlNodeListGetString(xmlNodePtr.pointee.doc, xmlAttrPtr?.pointee.children, 1)
                child.content = contentPtr?.withMemoryRebound(to: CChar.self, capacity: 0, { cStringPtr in
                    String(cString: cStringPtr, encoding: .utf8)
                }) ?? ""
                xmlFree(contentPtr)

                // Add the attribute Reader to
                parent.addChild(child)
            }

            // Advance current attribute to next in list
            xmlAttrPtr = xmlAttrPtr?.pointee.next
        }

        return parent
    }

    private static func namespace(_ ns: UnsafeMutablePointer<xmlNs>?) -> NodeInfo.Namespace? {
        guard let ns = ns?.pointee else { return nil }

        // Convert href to a Swift string
        guard let href = ns.href?.withMemoryRebound(to: CChar.self, capacity: 0, { cStringPtr in
            String(cString: cStringPtr, encoding: .utf8)
        }) else { return nil }

        // Convert prefix to a Swift string.  Prefix may be nil, defaults to "" in that case
        let prefix = ns.prefix?.withMemoryRebound(to: CChar.self, capacity: 0, { cStringPtr in
            String(cString: cStringPtr, encoding: .utf8)
        }) ?? ""

        return .init(prefix: prefix, uri: href)
    }
}

private extension xmlElementType {

    var nodeInfoLocation: NodeInfo.Location? {
        return switch self {
        case XML_ELEMENT_NODE: .element
        case XML_ATTRIBUTE_NODE: .attribute
        default: nil
        }
    }
}

private struct XMLError: Error {
    var localizedDescription: String

    init(_ localizedDescription: String) {
        self.localizedDescription = localizedDescription
    }

    static let memoryError = XMLError("XML buffer could not be allocated")
    static let invalidNode = XMLError("XML node was invalid")
    static let invalidNodeName = XMLError("XML node name was invalid")
}

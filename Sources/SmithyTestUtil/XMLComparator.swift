//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
#if canImport(FoundationXML)
// As of Swift 5.1, the Foundation module on Linux only has the same set of dependencies as the Swift standard library itself
// Therefore, we need to explicitly import FoundationXML on linux.
// The preferred way to do this, is to check if FoundationXML can be imported.
// https://github.com/apple/swift-corelibs-foundation/blob/main/Docs/ReleaseNotes_Swift5.md
import FoundationXML
#endif

public struct XMLComparator {
    /// Returns true if the XML documents, for the corresponding data objects, are equal.
    /// Order of elements within the document do not affect equality.
    /// - Parameters:
    ///   - dataA: The first data object to compare to the second data object.
    ///   - dataB: The second data object to compare to the first data object.
    /// - Returns: Returns true if the XML documents, for the corresponding data objects, are equal.
    public static func xmlData(_ dataA: Data, isEqualTo dataB: Data) -> Bool {
        let rootA = XMLConverter.xmlTree(with: dataA)
        let rootB = XMLConverter.xmlTree(with: dataB)
        return rootA == rootB
    }
}

private struct XMLElement: Hashable {
    var name: String
    var attributes: [String : String]?
    var string: String?
    var elements: Set<XMLElement> = []
    var prefixes: [String: String] = [:]
}

private class XMLConverter: NSObject {
    /// Keeps track of the value since `foundCharacters` can be called multiple times for the same element
    private var valueBuffer = ""
    private var stack: [XMLElement] = []

    static func xmlTree(with data: Data) -> XMLElement {
        let converter = XMLConverter()
        converter.stack.append(XMLElement(name: ""))

        let parser = XMLParser(data: data)
        parser.shouldProcessNamespaces = true
        parser.shouldReportNamespacePrefixes = true
        parser.delegate = converter
        parser.parse()

        return converter.stack.first!
    }
}

extension XMLConverter: XMLParserDelegate {
    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String : String] = [:]
    ) {
        let prefixes = stack.indices.last.map { stack[$0].prefixes } ?? [:]
        let element = XMLElement(
            name: Self.resolveName(name: elementName, prefixes: Array(prefixes.keys)),
            attributes: Dictionary(
                uniqueKeysWithValues: attributeDict.map {
                    (Self.resolveName(name: $0.key, prefixes: Array(prefixes.keys)), $0.value)
                }),
            prefixes: prefixes
        )
        stack.append(element)
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        valueBuffer.append(trimmedString)
    }

    func parser(
        _ parser: XMLParser, didEndElement
        elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        var element = stack.popLast()!
        var parent = stack.last!

        element.string = valueBuffer

        var elements = parent.elements
        elements.insert(element)
        parent.elements = elements

        stack[stack.endIndex - 1] = parent
        valueBuffer = ""
    }

    func parser(_ parser: XMLParser, didStartMappingPrefix prefix: String, toURI namespaceURI: String) {
        guard let last = stack.indices.last else { fatalError() }
        stack[last].prefixes[prefix] = namespaceURI
    }

    func parser(_ parser: XMLParser, didEndMappingPrefix prefix: String) {
        guard let last = stack.indices.last else { fatalError() }
        stack[last].prefixes[prefix] = nil
    }

    /// Strips any defined XML namespace prefixes off of an element or attribute name.
    /// - Parameters:
    ///   - name: The name to have its prefix stripped.
    ///   - prefixes: The prefixes that are defined for this node.
    /// - Returns: The name, with any prefix stripped off the front.
    fileprivate static func resolveName(name: String, prefixes: [String]) -> String {
        let components = name.split(separator: ":")
        if components.count == 1 {
            return String(components[0])
        } else if components.count == 2 {
            let prefix = String(components[0])
            let resolvedName = components[1]
            if prefixes.contains(prefix) {
                return String(resolvedName)
            } else {
                return name
            }
        } else {
            return name
        }
    }
}

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
    var name: String?
    var attributes: [String : String]?
    var string: String?
    var elements: Set<XMLElement> = []
}

private class XMLConverter: NSObject {
    /// Keeps track of the value since `foundCharacters` can be called multiple times for the same element
    private var valueBuffer = ""
    private var stack: [XMLElement] = []

    static func xmlTree(with data: Data) -> XMLElement {
        let converter = XMLConverter()
        converter.stack.append(XMLElement())

        let parser = XMLParser(data: data)
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
        let element = XMLElement(
            name: elementName,
            attributes: attributeDict
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
}

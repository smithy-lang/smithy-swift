//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public struct XMLComparator {
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
        let parent = stack.last!
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

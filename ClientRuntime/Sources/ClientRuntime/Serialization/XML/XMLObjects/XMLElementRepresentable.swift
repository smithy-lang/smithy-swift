/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

//  XMLElementRepresentable.swift
//  XMLParser

import Foundation

struct XMLElementRepresentable: Equatable {

    let key: String
    private(set) var stringValue: String?
    private(set) var elements: [XMLElementRepresentable] = []
    private(set) var attributes: [XMLAttributeRepresentable] = []
    private(set) var containsTextNodes: Bool = false

    var isStringNode: Bool {
        return key == ""
    }

    var isTextNode: Bool {
        return isStringNode
    }

    init(
        key: String,
        elements: [XMLElementRepresentable] = [],
        attributes: [XMLAttributeRepresentable] = []
    ) {
        self.key = key
        stringValue = nil
        self.elements = elements
        self.attributes = attributes
    }

    init(
        key: String,
        stringValue: String,
        attributes: [XMLAttributeRepresentable] = []
    ) {
        self.key = key
        elements = [XMLElementRepresentable(stringValue: stringValue)]
        self.attributes = attributes
        containsTextNodes = true
    }

    init(stringValue: String) {
        key = ""
        self.stringValue = stringValue
    }

    mutating func append(element: XMLElementRepresentable, forKey key: String) {
        elements.append(element)
        containsTextNodes = containsTextNodes || element.isTextNode
    }

    mutating func append(string: String) {
        if elements.last?.isTextNode == true {
            let oldValue = elements[elements.count - 1].stringValue ?? ""
            elements[elements.count - 1].stringValue = oldValue + string
        } else {
            elements.append(XMLElementRepresentable(stringValue: string))
        }
        containsTextNodes = true
    }

    func transformToKeyBasedContainer() -> XMLContainer {
        if isTextNode && stringValue != nil {
            return XMLStringContainer(stringValue!)
        }

        let attributes = XMLKeyBasedStorage(self.attributes.map { attribute in
            (key: attribute.key, value: XMLStringContainer(attribute.value) as XMLSimpleContainer)
        })
        let storage = XMLKeyBasedStorage<String, XMLContainer>()
        let elements = self.elements.reduce(storage) { $0.merge(element: $1) }
        return XMLKeyBasedContainer(elements: elements, attributes: attributes)
    }
}

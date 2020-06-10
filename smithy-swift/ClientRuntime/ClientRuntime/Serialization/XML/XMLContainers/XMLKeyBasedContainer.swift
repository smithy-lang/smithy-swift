//
//  XMLKeyBasedContainer.swift
//  XMLParser
//
// TODO:: Add copyrights
//

import Foundation

struct XMLKeyBasedContainer {
    
    var elements = XMLKeyBasedStorage<String, XMLContainer>() // why is this not simplecontainer?
    var attributes = XMLKeyBasedStorage<String, XMLSimpleContainer>()

    var unboxed: (elements: XMLKeyBasedStorage<String, XMLContainer>,
        attributes: XMLKeyBasedStorage<String, XMLSimpleContainer>) {
        return (
            elements: elements,
            attributes: attributes
        )
    }

    var value: XMLSimpleContainer? {
        return elements.values.first as? XMLSimpleContainer
    }
}

extension XMLKeyBasedContainer {
    init<E, A>(elements: E, attributes: A)
        where E: Sequence, E.Element == (String, XMLContainer),
        A: Sequence, A.Element == (String, XMLSimpleContainer) {
        let elements = XMLKeyBasedStorage<String, XMLContainer>(elements)
        let attributes = XMLKeyBasedStorage<String, XMLSimpleContainer>(attributes)
        self.init(elements: elements, attributes: attributes)
    }
}

extension XMLKeyBasedContainer: XMLContainer {
    var isNull: Bool {
        return false
    }
    
    var xmlString: String? {
        return nil
    }
}

extension XMLKeyBasedContainer: CustomStringConvertible {
    var description: String {
        return "{attributes: \(attributes), elements: \(elements)}"
    }
}

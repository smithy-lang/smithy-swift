//
//  XMLElementRepresentable+Extensions.swift
// TODO:: Add copyrights

import Foundation

extension XMLElementRepresentable {

    private static let escapedCharacterSet = [
        ("&", "&amp;"),
        ("<", "&lt;"),
        (">", "&gt;"),
        ("'", "&apos;"),
        ("\"", "&quot;")
    ]

    func toXMLString(with header: XMLHeader? = nil,
                     formatting: XMLEncoder.OutputFormatting) -> String {
        if let header = header, let headerXML = header.toXML() {
            return headerXML + _toXMLString(formatting: formatting)
        }
        return _toXMLString(formatting: formatting)
    }

    private func formatUnsortedXMLElements(
        _ string: inout String,
        _ level: Int,
        _ formatting: XMLEncoder.OutputFormatting,
        _ prettyPrinted: Bool
    ) {
        formatXMLElements(
            from: elements,
            into: &string,
            at: level,
            formatting: formatting,
            prettyPrinted: prettyPrinted
        )
    }

    fileprivate func elementString(
        for element: XMLElementRepresentable,
        at level: Int,
        formatting: XMLEncoder.OutputFormatting,
        prettyPrinted: Bool
    ) -> String {
        if let stringValue = element.stringValue {
            return stringValue.escape(XMLElementRepresentable.escapedCharacterSet)
        }

        var string = ""
        string += element._toXMLString(
            indented: level + 1, formatting: formatting
        )
        string += prettyPrinted ? "\n" : ""
        return string
    }

    fileprivate func formatSortedXMLElements(
        _ string: inout String,
        _ level: Int,
        _ formatting: XMLEncoder.OutputFormatting,
        _ prettyPrinted: Bool
    ) {
        formatXMLElements(from: elements.sorted { $0.key < $1.key },
                          into: &string,
                          at: level,
                          formatting: formatting,
                          prettyPrinted: prettyPrinted)
    }

    fileprivate func attributeString(key: String, value: String) -> String {
        return " \(key)=\"\(value.escape(XMLElementRepresentable.escapedCharacterSet))\""
    }

    fileprivate func formatXMLAttributes(
        from attributes: [XMLAttributeRepresentable],
        into string: inout String
    ) {
        for attribute in attributes {
            string += attributeString(key: attribute.key, value: attribute.value)
        }
    }

    fileprivate func formatXMLElements(
        from elements: [XMLElementRepresentable],
        into string: inout String,
        at level: Int,
        formatting: XMLEncoder.OutputFormatting,
        prettyPrinted: Bool
    ) {
        for element in elements {
            string += elementString(for: element,
                                    at: level,
                                    formatting: formatting,
                                    prettyPrinted: prettyPrinted && !containsTextNodes)
        }
    }

    fileprivate func formatSortedXMLAttributes(_ string: inout String) {
        formatXMLAttributes(
            from: attributes.sorted(by: { $0.key < $1.key }), into: &string
        )
    }

    fileprivate func formatUnsortedXMLAttributes(_ string: inout String) {
        formatXMLAttributes(from: attributes, into: &string)
    }

    private func formatXMLAttributes(
        _ formatting: XMLEncoder.OutputFormatting,
        _ string: inout String
    ) {
        if formatting.contains(.sortedKeys) {
            formatSortedXMLAttributes(&string)
            return
        }
        formatUnsortedXMLAttributes(&string)
    }

    private func formatXMLElements(
        _ formatting: XMLEncoder.OutputFormatting,
        _ string: inout String,
        _ level: Int,
        _ prettyPrinted: Bool
    ) {
        if formatting.contains(.sortedKeys) {
            formatSortedXMLElements(
                &string, level, formatting, prettyPrinted
            )
            return
        }
        formatUnsortedXMLElements(
            &string, level, formatting, prettyPrinted
        )
    }

    private func _toXMLString(
        indented level: Int = 0,
        formatting: XMLEncoder.OutputFormatting
    ) -> String {
        let prettyPrinted = formatting.contains(.prettyPrinted)
        let indentation = String(
            repeating: " ", count: (prettyPrinted ? level : 0) * 4
        )
        var string = indentation

        if !key.isEmpty {
            string += "<\(key)"
        }

        formatXMLAttributes(formatting, &string)

        if !elements.isEmpty {
            let prettyPrintElements = prettyPrinted && !containsTextNodes
            if !key.isEmpty {
                string += prettyPrintElements ? ">\n" : ">"
            }
            formatXMLElements(formatting, &string, level, prettyPrintElements)

            if prettyPrintElements { string += indentation }
            if !key.isEmpty {
                string += "</\(key)>"
            }
        } else {
            string += " />"
        }

        return string
    }
}

// MARK: - Convenience Initializers

extension XMLElementRepresentable {

    init(key: String,
         isStringBoxCDATA isCDATA: Bool,
         box: XMLArrayBasedContainer,
         attributes: [XMLAttributeRepresentable] = []) {
        self.init(
            key: key,
            elements: box.map { XMLElementRepresentable(key: key, isStringBoxCDATA: isCDATA, box: $0) },
            attributes: attributes
        )
    }

    init(key: String,
         isStringBoxCDATA isCDATA: Bool,
         box: XMLKeyBasedContainer,
         attributes: [XMLAttributeRepresentable] = []) {
        var elements: [XMLElementRepresentable] = []

        for (key, box) in box.elements {
            let fail = {
                preconditionFailure("Unclassified box: \(type(of: box))")
            }

            switch box {
            case let sharedUnkeyedBox as XMLSharedContainer<XMLArrayBasedContainer>:
                let box = sharedUnkeyedBox.unboxed
                elements.append(contentsOf: box.map {
                    XMLElementRepresentable(key: key, isStringBoxCDATA: isCDATA, box: $0)
                })
            case let unkeyedBox as XMLArrayBasedContainer:
                // This basically injects the unkeyed children directly into self:
                elements.append(contentsOf: unkeyedBox.map {
                    XMLElementRepresentable(key: key, isStringBoxCDATA: isCDATA, box: $0)
                })
            case let sharedKeyedBox as XMLSharedContainer<XMLKeyBasedContainer>:
                let box = sharedKeyedBox.unboxed
                elements.append(XMLElementRepresentable(key: key, isStringBoxCDATA: isCDATA, box: box))
            case let keyedBox as XMLKeyBasedContainer:
                elements.append(XMLElementRepresentable(key: key, isStringBoxCDATA: isCDATA, box: keyedBox))
            case let simpleBox as XMLSimpleContainer:
                elements.append(XMLElementRepresentable(key: key, isStringBoxCDATA: isCDATA, box: simpleBox))
            default:
                fail()
            }
        }

        let attributes: [XMLAttributeRepresentable] = attributes + box.attributes.compactMap { key, box in
            guard let value = box.xmlString else {
                return nil
            }
            return XMLAttributeRepresentable(key: key, value: value)
        }

        self.init(key: key, elements: elements, attributes: attributes)
    }

    init(key: String, isStringBoxCDATA: Bool, box: XMLSimpleContainer) {
        if let value = box.xmlString {
            self.init(key: key, stringValue: value)
        } else {
            self.init(key: key)
        }
    }

    init(key: String, isStringBoxCDATA isCDATA: Bool, box: XMLContainer, attributes: [XMLAttributeRepresentable] = []) {
        switch box {
        case let sharedUnkeyedBox as XMLSharedContainer<XMLArrayBasedContainer>:
            self.init(key: key, isStringBoxCDATA: isCDATA, box: sharedUnkeyedBox.unboxed, attributes: attributes)
        case let sharedKeyedBox as XMLSharedContainer<XMLKeyBasedContainer>:
            self.init(key: key, isStringBoxCDATA: isCDATA, box: sharedKeyedBox.unboxed, attributes: attributes)
        case let unkeyedBox as XMLArrayBasedContainer:
            self.init(key: key, isStringBoxCDATA: isCDATA, box: unkeyedBox, attributes: attributes)
        case let keyedBox as XMLKeyBasedContainer:
            self.init(key: key, isStringBoxCDATA: isCDATA, box: keyedBox, attributes: attributes)
        case let simpleBox as XMLSimpleContainer:
            self.init(key: key, isStringBoxCDATA: isCDATA, box: simpleBox)
        case let box:
            preconditionFailure("Unclassified box: \(type(of: box))")
        }
    }
}

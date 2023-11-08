//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

class SingleValueEncodingContainer: Swift.SingleValueEncodingContainer {
    let element: XMLElement
    var codingPath: [CodingKey]
    let userInfo: [CodingUserInfoKey: Any]

    init(element: XMLElement, codingPath: [CodingKey], userInfo: [CodingUserInfoKey: Any]) {
        self.element = element
        self.codingPath = codingPath
        self.userInfo = userInfo
    }

    func encodeNil() throws {
        record(string: "null")
    }

    func encode(_ value: Bool) throws {
        record(string: value ? "true" : "false")
    }

    func encode(_ value: String) throws {
        record(string: value)
    }

    func encode(_ value: Double) throws {
        guard !value.isNaN else {
            record(string: "NaN")
            return
        }
        switch value {
        case .infinity:
            record(string: "Infinity")
        case -.infinity:
            record(string: "-Infinity")
        default:
            record(string: "\(value)")
        }
    }

    func encode(_ value: Float) throws {
        guard !value.isNaN else {
            record(string: "NaN")
            return
        }
        switch value {
        case .infinity:
            record(string: "Infinity")
        case -.infinity:
            record(string: "-Infinity")
        default:
            record(string: "\(value)")
        }
    }

    func encode(_ value: Int) throws {
        record(string: "\(value)")
    }

    func encode(_ value: Int8) throws {
        record(string: "\(value)")
    }

    func encode(_ value: Int16) throws {
        record(string: "\(value)")
    }

    func encode(_ value: Int32) throws {
        record(string: "\(value)")
    }

    func encode(_ value: Int64) throws {
        record(string: "\(value)")
    }

    func encode(_ value: UInt) throws {
        record(string: "\(value)")
    }

    func encode(_ value: UInt8) throws {
        record(string: "\(value)")
    }

    func encode(_ value: UInt16) throws {
        record(string: "\(value)")
    }

    func encode(_ value: UInt32) throws {
        record(string: "\(value)")
    }

    func encode(_ value: UInt64) throws {
        record(string: "\(value)")
    }

    func encode<T: Encodable>(_ value: T) throws {
        let encoder = Encoder(element: element, codingPath: codingPath, userInfo: userInfo)
        try value.encode(to: encoder)
    }

    private func record(string: String) {
        guard let key = codingPath.last else { return }
        let xmlKey = codingPath.last as? XMLCodingKey
        switch xmlKey?.kind ?? .element {
        case .attribute:
            guard let parent = element.parent as? XMLElement else { break }
            let attribute = XMLNode(kind: .attribute)
            attribute.name = key.stringValue
            attribute.stringValue = string
            parent.addAttribute(attribute)
            element.detach()
        case .element:
            element.stringValue = string
        default:
            fatalError("Unhandled type of XML node")
        }
    }
}

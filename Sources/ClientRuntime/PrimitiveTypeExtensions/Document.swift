/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

//import SmithyXML

public enum Document {
    case array([Document])
    case boolean(Bool)
    case number(Double)
    case object([String: Document])
    case string(String)
    case null
}

//extension Document {
//
//    static func writingClosure(_ value: Document?, to writer: SmithyXML.Writer) throws {
//        guard let value else { writer.detach; return }
//        switch self {
//        case .array(let array):
//            writer["array"].writeList(array, memberWritingClosure: Self.writingClosure(_:to:), memberNodeInfo: .init("member"), isFlattened: false)
//        }
//    }
//
//    static func readingClosure(from reader: SmithyXML.Reader) throws -> Document {
//
//    }
//}

extension Document: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode([String: Document].self) {
            self = .object(value)
        } else if let value = try? container.decode([Document].self) {
            self = .array(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .boolean(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else {
            self = .null
        }
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .array(let value):
            try container.encode(value)
        case .boolean(let value):
            try container.encode(value)
        case .number(let value):
            try container.encode(value)
        case .object(let value):
            try container.encode(value)
        case .string(let value):
            try container.encode(value)
        case .null:
            try container.encodeNil()
        }
    }
}
extension Document: Equatable { }
extension Document: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: Document...) {
        self = .array(elements)
    }
}
extension Document: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .boolean(value)
    }
}
extension Document: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, Document)...) {
        let dictionary = elements.reduce([String: Document]()) { acc, curr in
            var newValue = acc
            newValue[curr.0] = curr.1
            return newValue
        }
        self = .object(dictionary)
    }
}
extension Document: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) {
        self = .number(value)
    }
}
extension Document: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .number(Double(value))
    }
}
extension Document: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .null
    }
}
extension Document: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}
// extension to use subscribts to get the values from objects/arrays as normal
public extension Document {
    subscript(_ key: String) -> Document? {
        guard case .object(let object) = self else {
            return nil
        }
        return object[key]
    }
    subscript(_ key: Int) -> Document? {
        switch self {
        case .array(let array):
            return array[key]
        case .object(let object):
            return object["\(key)"]
        default:
            return nil
        }
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import struct Foundation.Data
import class Foundation.JSONSerialization
import class Foundation.NSNull
import class Foundation.NSNumber
import func CoreFoundation.CFGetTypeID
import func CoreFoundation.CFBooleanGetTypeID

public enum Document {
    case array([Document])
    case boolean(Bool)
    case number(Double)
    case object([String: Document])
    case string(String)
    case null
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

extension Document {

    private var jsonObject: Any {
        switch self {
        case .array(let array):
            return array.map { $0.jsonObject }
        case .boolean(let bool):
            return bool
        case .number(let double):
            return double
        case .object(let object):
            return object.mapValues { $0.jsonObject }
        case .string(let string):
            return string
        case .null:
            return NSNull()
        }
    }

    public static func make(from jsonObject: Any) throws -> Document {
        if let object = jsonObject as? [String: Any] {
            return .object(try object.mapValues { try Document.make(from: $0) })
        } else if let array = jsonObject as? [Any] {
            return .array(try array.map { try Document.make(from: $0) })
        } else if let nsNumber = jsonObject as? NSNumber, CFGetTypeID(nsNumber) == CFBooleanGetTypeID() {
            return .boolean(nsNumber.boolValue)
        } else if let nsNumber = jsonObject as? NSNumber {
            return .number(nsNumber.doubleValue)
        } else if let string = jsonObject as? String {
            return .string(string)
        } else if jsonObject is NSNull {
            return .null
        } else {
            throw SmithyDocumentError.invalidJSONData
        }
    }

    public static func document(from data: Data) throws -> Document {
        let jsonObject = try JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        return try Document.make(from: jsonObject)
    }
}

enum SmithyDocumentError: Error {
    case invalidJSONData
}

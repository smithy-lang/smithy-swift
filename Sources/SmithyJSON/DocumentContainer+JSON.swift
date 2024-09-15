//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SmithyDocumentImpl) import Smithy

extension Document: ExpressibleByArrayLiteral {
    public init(arrayLiteral value: Document...) {
        self = .init(document: ListDocument(value: value))
    }
}

extension Document: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .init(document: BooleanDocument(value: value))
    }
}

extension Document: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, Document)...) {
        let value = elements.reduce([String: Document]()) { acc, curr in
            var newValue = acc
            newValue[curr.0] = curr.1
            return newValue
        }
        self = .init(document: StringMapDocument(value: value))
    }
}

extension Document: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Float) {
        self = .init(document: FloatDocument(value: value))
    }
}

extension Document: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .init(document: IntegerDocument(value: value))
    }
}

extension Document: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .init(document: NullDocument())
    }
}

extension Document: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .init(document: StringDocument(value: value))
    }
}

// extension to use subscripts to get the values from objects/arrays as normal
// Swift subscripts are non-throwing, so suppress any error to `nil` with `try?`
public extension Document {

    subscript(_ key: String) -> Document? {
        switch type {
        case .map:
            return (try? getMember(key)).map { Document(document: $0) }
        default:
            return nil
        }
    }

    subscript(_ key: Int) -> Document? {
        switch self.type {
        case .list:
            return (try? asList()).map { Document(document: $0[key]) }
        default:
            return nil
        }
    }
}

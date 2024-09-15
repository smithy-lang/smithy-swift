//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SmithyDocumentImpl) import Smithy

extension DocumentContainer: ExpressibleByArrayLiteral {
    public init(arrayLiteral value: DocumentContainer...) {
        self = .init(document: ListDocument(value: value))
    }
}

extension DocumentContainer: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .init(document: BooleanDocument(value: value))
    }
}

extension DocumentContainer: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, DocumentContainer)...) {
        let value = elements.reduce([String: DocumentContainer]()) { acc, curr in
            var newValue = acc
            newValue[curr.0] = curr.1
            return newValue
        }
        self = .init(document: StringMapDocument(value: value))
    }
}

extension DocumentContainer: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Float) {
        self = .init(document: FloatDocument(value: value))
    }
}

extension DocumentContainer: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) {
        self = .init(document: IntegerDocument(value: value))
    }
}

extension DocumentContainer: ExpressibleByNilLiteral {
    public init(nilLiteral: ()) {
        self = .init(document: NullDocument())
    }
}

extension DocumentContainer: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .init(document: StringDocument(value: value))
    }
}

// extension to use subscripts to get the values from objects/arrays as normal
// Swift subscripts are non-throwing, so suppress any error to `nil` with `try?`
public extension DocumentContainer {

    subscript(_ key: String) -> Document? {
        switch type {
        case .map:
            return try? getMember(key)
        default:
            return nil
        }
    }

    subscript(_ key: Int) -> Document? {
        switch self.type {
        case .list:
            return try? asList()[key]
        default:
            return nil
        }
    }
}

//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@_spi(SmithyDocumentImpl) import Smithy

extension Document: ExpressibleByArrayLiteral {

    public init(arrayLiteral value: Document...) {
        self.init(ListDocument(value: value))
    }
}

extension Document: ExpressibleByBooleanLiteral {

    public init(booleanLiteral value: Bool) {
        self.init(BooleanDocument(value: value))
    }
}

extension Document: ExpressibleByDictionaryLiteral {

    public init(dictionaryLiteral elements: (String, Document)...) {
        let value = elements.reduce([String: Document]()) { acc, curr in
            var newValue = acc
            newValue[curr.0] = curr.1
            return newValue
        }
        self.init(StringMapDocument(value: value))
    }
}

extension Document: ExpressibleByFloatLiteral {

    public init(floatLiteral value: Float) {
        self.init(FloatDocument(value: value))
    }
}

extension Document: ExpressibleByIntegerLiteral {

    public init(integerLiteral value: Int) {
        self.init(IntegerDocument(value: value))
    }
}

extension Document: ExpressibleByNilLiteral {

    public init(nilLiteral: ()) {
        self.init(NullDocument())
    }
}

extension Document: ExpressibleByStringLiteral {

    public init(stringLiteral value: String) {
        self.init(StringDocument(value: value))
    }
}

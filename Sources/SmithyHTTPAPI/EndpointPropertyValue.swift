//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Smithy
import enum AwsCommonRuntimeKit.EndpointProperty

public enum EndpointPropertyValue: Sendable, Equatable {
    case bool(Bool)
    case string(String)
    indirect case array([EndpointPropertyValue])
    indirect case dictionary([String: EndpointPropertyValue])
}

public extension EndpointPropertyValue {
    // Convenience for string literals
    init(_ string: String) { self = .string(string) }
    init(_ bool: Bool) { self = .bool(bool) }
}

extension EndpointPropertyValue {
    init(_ endpointProperty: EndpointProperty) {
        switch endpointProperty {
        case .bool(let value):
            self = .bool(value)
        case .string(let value):
            self = .string(value)
        case .array(let values):
            self = .array(values.map(EndpointPropertyValue.init))
        case .dictionary(let dict):
            self = .dictionary(dict.mapValues(EndpointPropertyValue.init))
        }
    }
}

extension EndpointPropertyValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self = .string(value)
    }
}

extension EndpointPropertyValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
}

extension EndpointPropertyValue: ExpressibleByArrayLiteral {
    public init(arrayLiteral elements: EndpointPropertyValue...) {
        self = .array(elements)
    }
}

extension EndpointPropertyValue: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, EndpointPropertyValue)...) {
        self = .dictionary(Dictionary(uniqueKeysWithValues: elements))
    }
}

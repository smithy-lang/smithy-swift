//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

//import enum AwsCommonRuntimeKit.EndpointProperty
import Foundation
import Smithy

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

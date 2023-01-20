// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0.

/// Type safe property bag key
public struct AttributeKey<ValueType>: Hashable {
    let name: String

    public init(name: String) {
        self.name = name
    }

    func toString() -> String {
        return "AttributeKey: \(name)"
    }
}
/// Type safe property bag
public struct Attributes {
    var attributes: [Int: Any] = [Int: Any]()

    public init() {}

    public func get<T: Any>(key: AttributeKey<T>) -> T? {
        return attributes[key.hashValue] as? T
    }

    public func contains<T>(key: AttributeKey<T>) -> Bool {
        return attributes[key.hashValue] != nil && (attributes[key.hashValue] as? T) != nil
    }

    public mutating func set<T: Any>(key: AttributeKey<T>, value: T?) {
        attributes[key.hashValue] = value
    }

    public mutating func remove<T>(key: AttributeKey<T>) {
        attributes.removeValue(forKey: key.hashValue)
    }
}

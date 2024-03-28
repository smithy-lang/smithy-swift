//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

/// Type safe property bag key
public struct AttributeKey<ValueType> {
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
    private var attributes = [String: Any]()
    public var size: Int { attributes.count }

    public init() {}

    public func get<T>(key: AttributeKey<T>) -> T? {
        attributes[key.name] as? T
    }

    public func contains<T>(key: AttributeKey<T>) -> Bool {
        get(key: key) != nil
    }

    public mutating func set<T>(key: AttributeKey<T>, value: T?) {
        attributes[key.name] = value
    }

    public mutating func remove<T>(key: AttributeKey<T>) {
        attributes.removeValue(forKey: key.name)
    }
}

/// A type that can be used as a type-safe property bag.
public protocol HasAttributes: AnyObject {
    /// - Parameter key: The key of the attribute to get.
    /// - Returns: The attribute, if it exists.
    func get<T>(key: AttributeKey<T>) -> T?

    /// - Parameter key: The key of the attribute to get.
    /// - Returns: `true` if the property bag contains a value for the specified `key`, otherwise `false`.
    func contains<T>(key: AttributeKey<T>) -> Bool

    /// - Parameters:
    ///   - key: The key to associate with `value`.
    ///   - value: The value to set in the property bag.
    func set<T>(key: AttributeKey<T>, value: T)

    /// - Parameter key: The key of the attribute to remove from the property bag.
    func remove<T>(key: AttributeKey<T>)
}

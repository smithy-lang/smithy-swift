//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import class Foundation.NSRecursiveLock

public class Context {
    private var _attributes: Attributes
    private let lock = NSRecursiveLock()

    public init(attributes: Attributes) {
        self._attributes = attributes
    }

    public func toBuilder() -> ContextBuilder {
        ContextBuilder(attributes: accessAttributes())
    }

    public func getLogger() -> LogAgent? {
        return accessAttributes().get(key: AttributeKeys.logger)
    }

    @discardableResult
    private func accessAttributes(accessor: ((inout Attributes) -> Void)? = nil) -> Attributes {
        lock.lock()
        defer { lock.unlock() }
        accessor?(&_attributes)
        return _attributes
    }
}

extension Context {

    public func get<T: Sendable>(key: AttributeKey<T>) -> T? {
        accessAttributes().get(key: key)
    }

    public func contains<T: Sendable>(key: AttributeKey<T>) -> Bool {
        accessAttributes().contains(key: key)
    }

    public func set<T: Sendable>(key: AttributeKey<T>, value: T?) {
        accessAttributes { attributes in
            attributes.set(key: key, value: value)
        }
    }

    public func remove<T>(key: AttributeKey<T>) {
        accessAttributes { attributes in
            attributes.remove(key: key)
        }
    }
}

public class ContextBuilder {

    public init(attributes: Attributes = Attributes()) {
        self.attributes = attributes
    }

    public var attributes: Attributes

    // We follow the convention of returning the builder object
    // itself from any configuration methods, and by adding the
    // @discardableResult attribute we won't get warnings if we
    // don't end up doing any chaining.
    @discardableResult
    public func with<T: Sendable>(key: AttributeKey<T>, value: T) -> Self {
        self.attributes.set(key: key, value: value)
        return self
    }

    @discardableResult
    public func withLogger(value: LogAgent) -> Self {
        self.attributes.set(key: AttributeKeys.logger, value: value)
        return self
    }

    public func build() -> Context {
        return Context(attributes: attributes)
    }
}

enum AttributeKeys {
    public static let logger = AttributeKey<LogAgent>(name: "Logger")
}

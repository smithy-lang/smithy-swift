//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public class Context {
    public var attributes: Attributes

    public init(attributes: Attributes) {
        self.attributes = attributes
    }

    public func toBuilder() -> ContextBuilder {
        let builder = ContextBuilder()
        builder.attributes = self.attributes
        return builder
    }

    public func getLogger() -> LogAgent? {
        return attributes.get(key: AttributeKeys.logger)
    }
}

extension Context {
    public func get<T>(key: AttributeKey<T>) -> T? {
        self.attributes.get(key: key)
    }

    public func contains<T>(key: AttributeKey<T>) -> Bool {
        self.attributes.contains(key: key)
    }

    public func set<T>(key: AttributeKey<T>, value: T?) {
        self.attributes.set(key: key, value: value)
    }

    public func remove<T>(key: AttributeKey<T>) {
        self.attributes.remove(key: key)
    }
}

public class ContextBuilder {
    public init() {}

    public var attributes: Attributes = Attributes()

    // We follow the convention of returning the builder object
    // itself from any configuration methods, and by adding the
    // @discardableResult attribute we won't get warnings if we
    // don't end up doing any chaining.
    @discardableResult
    public func with<T>(key: AttributeKey<T>, value: T) -> Self {
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

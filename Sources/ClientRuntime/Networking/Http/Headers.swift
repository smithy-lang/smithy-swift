/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import AwsCommonRuntimeKit

public struct Headers {
    public var headers: [Header] = []

    /// Creates an empty instance.
    public init() {}

    /// Creates an instance from a `[String: String]`. Duplicate case-insensitive names are collapsed into the last name
    /// and value encountered.
    public init(_ dictionary: [String: String]) {
        self.init()

        dictionary.forEach { add(name: $0.key, value: $0.value)}
    }

    /// Creates an instance from a `[String: [String]]`.
    public init(_ dictionary: [String: [String]]) {
        self.init()

        dictionary.forEach { key, values in add(name: key, values: values) }
    }

    /// Case-insensitively updates or appends a `Header` into the instance using the provided `name` and `value`.
    ///
    /// - Parameters:
    ///   - name:  The `String` name.
    ///   - value: The `String` value.
    public mutating func add(name: String, value: String) {
        let header = Header(name: name, value: value)
        add(header)
    }

    /// Case-insensitively updates the value of a `Header` by appending the new values to it or appends a `Header`
    /// into the instance using the provided `name` and `values`.
    ///
    /// - Parameters:
    ///   - name:  The `String` name.
    ///   - values: The `[String]` values.
    public mutating func add(name: String, values: [String]) {
        let header = Header(name: name, values: values)
        add(header)
    }

    /// Case-insensitively updates the value of a `Header` by appending the new values to it or appends a `Header`
    /// into the instance using the provided `Header`.
    ///
    /// - Parameters:
    ///   - header:  The `Header` to be added or updated.
    public mutating func add(_ header: Header) {
        guard let index = headers.index(of: header.name) else {
            headers.append(header)
            return
        }
        headers[index].value.append(contentsOf: header.value)
    }

    /// Case-insensitively updates the value of a `Header` by replacing the values of it or appends a `Header`
    /// into the instance if it does not exist using the provided `Header`.
    ///
    /// - Parameters:
    ///   - header:  The `Header` to be added or updated.
    public mutating func update(_ header: Header) {
        guard let index = headers.index(of: header.name) else {
            headers.append(header)
            return
        }
        headers.replaceSubrange(index...index, with: [header])
    }

    /// Case-insensitively updates the value of a `Header` by replacing the values of it or appends a `Header`
    /// into the instance if it does not exist using the provided `Header`.
    ///
    /// - Parameters:
    ///   - header:  The `Header` to be added or updated.
    public mutating func update(name: String, value: [String]) {
        let header = Header(name: name, values: value)
        update(header)
    }

    /// Case-insensitively updates the value of a `Header` by replacing the values of it or appends a `Header`
    /// into the instance if it does not exist using the provided `Header`.
    ///
    /// - Parameters:
    ///   - header:  The `Header` to be added or updated.
    public mutating func update(name: String, value: String) {
        let header = Header(name: name, value: value)
        update(header)
    }

    /// Case-insensitively adds all `Headers` into the instance using the provided `[Headers]` array.
    ///
    /// - Parameters:
    ///   - headers:  The `Headers` object.
    public mutating func addAll(headers: Headers) {
        self.headers.append(contentsOf: headers.headers)
    }

    /// Case-insensitively removes a `Header`, if it exists, from the instance.
    ///
    /// - Parameter name: The name of the `HTTPHeader` to remove.
    public mutating func remove(name: String) {
        guard let index = headers.index(of: name) else { return }

        headers.remove(at: index)
    }

    /// Case-insensitively find a header's values by name.
    ///
    /// - Parameter name: The name of the header to search for, case-insensitively.
    ///
    /// - Returns: The values of the header, if they exist.
    public func values(for name: String) -> [String]? {
        guard let indices = headers.indices(of: name), !indices.isEmpty else { return nil }
        var values = [String]()
        for index in indices {
            values.append(contentsOf: headers[index].value)
        }

        return values
    }

    /// Case-insensitively find a header's value by name.
    ///
    /// - Parameter name: The name of the header to search for, case-insensitively.
    ///
    /// - Returns: The value of header as a comma delimited string, if it exists.
    public func value(for name: String) -> String? {
        guard let values = values(for: name) else {
            return nil
        }
        return values.joined(separator: ",")
    }

    public func exists(name: String) -> Bool {
        guard headers.index(of: name) != nil else {
            return false
        }

        guard let value = value(for: name) else {
            return false
        }

        return !value.isEmpty
    }

    /// The dictionary representation of all headers.
    ///
    /// This representation does not preserve the current order of the instance.
    public var dictionary: [String: [String]] {
        let namesAndValues = headers.map { ($0.name, $0.value) }

        return Dictionary(namesAndValues) { (first, last) -> [String] in
            return first + last
        }
    }

    public var isEmpty: Bool {
        return self.headers.isEmpty
    }
}

extension Headers: Equatable {
    /// Returns a boolean value indicating whether two values are equal irrespective of order.
    /// - Parameters:
    ///   - lhs: The first `Headers` to compare.
    ///   - rhs: The second `Headers` to compare.
    /// - Returns: `true` if the two values are equal irrespective of order, otherwise `false`.
    public static func == (lhs: Headers, rhs: Headers) -> Bool {
        return lhs.headers.sorted() == rhs.headers.sorted()
    }
}

extension Headers: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(headers.sorted())
    }
}

extension Array where Element == Header {
    /// Case-insensitively finds the index of an `Header` with the provided name, if it exists.
    func index(of name: String) -> Int? {
        let lowercasedName = name.lowercased()
        return firstIndex { $0.name.lowercased() == lowercasedName }
    }

    /// Case-insensitively finds the indexes of an `Header` with the provided name, if it exists.
    func indices(of name: String) -> [Int]? {
        let lowercasedName = name.lowercased()
        return enumerated().compactMap { $0.element.name.lowercased() == lowercasedName ? $0.offset : nil }
    }
}

public struct Header {
    public var name: String
    public var value: [String]

    public init(name: String, values: [String]) {
        self.name = name
        self.value = values
    }

    public init(name: String, value: String) {
        self.name = name
        self.value = [value]
    }
}

extension Header: Equatable {
    public static func == (lhs: Header, rhs: Header) -> Bool {
        return lhs.name == rhs.name && lhs.value.sorted() == rhs.value.sorted()
    }
}

extension Header: Hashable {

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(value.sorted())
    }
}

extension Header: Comparable {
    /// Compares two `Header` instances by name.
    /// - Parameters:
    ///  - lhs: The first `Header` to compare.
    /// - rhs: The second `Header` to compare.
    /// - Returns: `true` if the first `Header`'s name is less than the second `Header`'s name, otherwise `false`.
    public static func < (lhs: Header, rhs: Header) -> Bool {
        return lhs.name < rhs.name
    }
}

extension Headers {
    public func toHttpHeaders() -> [HTTPHeader] {
        headers.map {
            HTTPHeader(name: $0.name, value: $0.value.joined(separator: ","))
        }
    }

    init(httpHeaders: [HTTPHeader]) {
        self.init()
        addAll(httpHeaders: httpHeaders)
    }

    public mutating func addAll(httpHeaders: [HTTPHeader]) {
        httpHeaders.forEach {
            add(name: $0.name, value: $0.value)
        }
    }
}

extension Headers: CustomDebugStringConvertible {
    public var debugDescription: String {
        return dictionary.map {"\($0.key): \($0.value.joined(separator: ", "))"}.joined(separator: ", \n")
    }
}

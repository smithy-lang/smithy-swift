//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

public struct Headers: Sendable {

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
    public mutating func addAll(headers otherHeaders: Headers) {
        headers.append(contentsOf: otherHeaders.headers)
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
        var values: [String]?
        for header in headers where header.name.isCaseInsensitivelyEqual(to: name) {
            if values == nil {
                // A name almost always matches a single header, whose values are then returned
                // as-is rather than copied into a fresh array.
                values = header.value
            } else {
                values?.append(contentsOf: header.value)
            }
        }
        return values
    }

    /// Case-insensitively find a header's value by name.
    ///
    /// - Parameter name: The name of the header to search for, case-insensitively.
    ///
    /// - Returns: The value of header as a comma delimited string, if it exists.
    public func value(for name: String) -> String? {
        guard let values = values(for: name) else { return nil }
        return values.joined(separator: ",")
    }

    public func exists(name: String) -> Bool {
        headers.index(of: name) != nil
    }

    /// The dictionary representation of all headers.
    ///
    /// This representation does not preserve the current order of the instance.
    public var dictionary: [String: [String]] {
        let namesAndValues = headers.map { ($0.name, $0.value) }
        return Dictionary(namesAndValues) { (first, last) -> [String] in
            first + last
        }
    }

    public var isEmpty: Bool {
        headers.isEmpty
    }
}

extension Headers: Equatable {
    /// Returns a boolean value indicating whether two values are equal irrespective of order.
    /// - Parameters:
    ///   - lhs: The first `Headers` to compare.
    ///   - rhs: The second `Headers` to compare.
    /// - Returns: `true` if the two values are equal irrespective of order, otherwise `false`.
    public static func == (lhs: Headers, rhs: Headers) -> Bool {
        let lhsHeaders = lhs.headers.sorted()
        let rhsHeaders = rhs.headers.sorted()
        return lhsHeaders == rhsHeaders
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
        firstIndex { $0.name.isCaseInsensitivelyEqual(to: name) }
    }
}

extension String {

    /// Whether this string and `other` are equal, ignoring case.
    ///
    /// An HTTP field name is a token, and so is ASCII, by specification:
    /// https://www.rfc-editor.org/rfc/rfc9110#section-5.1
    /// Equality is therefore decided by comparing UTF-8 bytes with ASCII case folding, which unlike
    /// `lowercased()` allocates nothing.  ASCII case folding also preserves length, so names of
    /// different lengths are rejected without comparing them at all.
    ///
    /// Header names are compared once per stored header on every lookup, so this is on the hot path
    /// for both request serialization and response deserialization.
    func isCaseInsensitivelyEqual(to other: String) -> Bool {
        let lhs = self.utf8
        let rhs = other.utf8
        guard lhs.count == rhs.count else { return false }
        var lhsIterator = lhs.makeIterator()
        var rhsIterator = rhs.makeIterator()
        while let lhsByte = lhsIterator.next(), let rhsByte = rhsIterator.next() {
            guard lhsByte.asciiLowercased == rhsByte.asciiLowercased else { return false }
        }
        return true
    }

    /// Whether this string begins with `prefix`, ignoring case.
    ///
    /// Folds ASCII case over UTF-8 bytes for the same reasons as ``isCaseInsensitivelyEqual(to:)``.
    func hasCaseInsensitivePrefix(_ prefix: String) -> Bool {
        var iterator = self.utf8.makeIterator()
        for prefixByte in prefix.utf8 {
            guard let byte = iterator.next() else { return false } // This string is the shorter one.
            guard byte.asciiLowercased == prefixByte.asciiLowercased else { return false }
        }
        return true
    }
}

extension UInt8 {

    /// This byte, lowercased if it is an uppercase ASCII letter and unchanged otherwise.
    @inline(__always)
    var asciiLowercased: UInt8 {
        (UInt8(ascii: "A")...UInt8(ascii: "Z")).contains(self) ? self | 0x20 : self
    }
}

public struct Header: Sendable {
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

extension Headers: CustomDebugStringConvertible {
    public var debugDescription: String {
        return dictionary.map {"\($0.key): \($0.value.joined(separator: ", "))"}.joined(separator: ", \n")
    }
}

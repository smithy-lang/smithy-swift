/*
 * Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
 * SPDX-License-Identifier: Apache-2.0.
 */

import Foundation

struct XMLKeyBasedStorage<Key: Hashable & Comparable, Value> {

    typealias Buffer = [(Key, Value)]

    fileprivate var keyIndicesInBuffer = [Key: [Int]]()
    fileprivate var buffer = Buffer()

    var isEmpty: Bool {
        return buffer.isEmpty
    }

    var count: Int {
        return buffer.count
    }

    var keys: [Key] {
        return buffer.map { $0.0 }
    }

    var values: [Value] {
        return buffer.map { $0.1 }
    }

    init<S>(_ sequence: S) where S: Sequence, S.Element == (Key, Value) {
        buffer = Buffer()
        keyIndicesInBuffer = [Key: [Int]]()
        sequence.forEach { key, value in append(value, at: key) }
    }

    subscript(key: Key) -> [Value] {
        return keyIndicesInBuffer[key]?.map { buffer[$0].1 } ?? []
    }

    mutating func append(_ value: Value, at key: Key) {
        let bufferCount = buffer.count
        buffer.append((key, value))
        if keyIndicesInBuffer[key] != nil {
            keyIndicesInBuffer[key]?.append(bufferCount)
        } else {
            keyIndicesInBuffer[key] = [bufferCount]
        }
    }

    func map<T>(_ transform: (Key, Value) throws -> T) rethrows -> [T] {
        return try buffer.map(transform)
    }

    func compactMap<T>(
        _ transform: ((Key, Value)) throws -> T?
    ) rethrows -> [T] {
        return try buffer.compactMap(transform)
    }

    init() {}
}

extension XMLKeyBasedStorage where Key == String, Value == XMLContainer {
    func merge(element: XMLElementRepresentable) -> XMLKeyBasedStorage<String, XMLContainer> {
        var result = self

        let hasElements = !element.elements.isEmpty
        let hasAttributes = !element.attributes.isEmpty
        let hasText = element.stringValue != nil

        if hasElements || hasAttributes {
            result.append(element.transformToKeyBasedContainer(), at: element.key)
        } else if hasText {
            result.append(element.transformToKeyBasedContainer(), at: element.key)
        } else {
            result.append(XMLSimpleKeyBasedContainer(key: element.key, element: XMLNullContainer()), at: element.key)
        }

        return result
    }
}

extension XMLKeyBasedStorage: Sequence {
    func makeIterator() -> Buffer.Iterator {
        return buffer.makeIterator()
    }
}

extension XMLKeyBasedStorage: CustomStringConvertible {
    var description: String {
        let result = buffer.map { "\"\($0)\": \($1)" }.joined(separator: ", ")

        return "[\(result)]"
    }
}
